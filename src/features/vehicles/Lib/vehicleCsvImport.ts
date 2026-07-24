export type CsvRow = Record<string, string>

export type ImportedVehicle = {
  source: 'map-assets' | 'samsara-gateways'
  externalId: string
  assetType: 'truck' | 'trailer'
  make: string
  model: string
  year: number
  vin: string | null
  licensePlate: string | null
  mileage: number
  trackingAddress: string | null
  trackingStatus: string | null
  trackingLastSeenAt: Date | null
  trackingCargoStatus: string | null
  trackingSpeed: number | null
  trackingHeading: number | null
}

function parseCsvLine(line: string) {
  const values: string[] = []
  let value = ''
  let quoted = false

  for (let index = 0; index < line.length; index += 1) {
    const character = line[index]
    if (character === '"') {
      if (quoted && line[index + 1] === '"') {
        value += '"'
        index += 1
      } else {
        quoted = !quoted
      }
    } else if (character === ',' && !quoted) {
      values.push(value.trim())
      value = ''
    } else {
      value += character
    }
  }

  values.push(value.trim())
  return values
}

export function parseCsv(csv: string): CsvRow[] {
  const lines = csv
    .replace(/^\uFEFF/, '')
    .split(/\r?\n/)
    .filter((line) => line.trim())
  if (lines.length < 2) return []

  const headers = parseCsvLine(lines[0])
  return lines.slice(1).map((line) => {
    const values = parseCsvLine(line)
    return Object.fromEntries(headers.map((header, index) => [header, values[index] ?? '']))
  })
}

function clean(value: string | undefined) {
  const trimmed = value?.trim()
  return !trimmed || trimmed.toLowerCase() === 'n/a' || trimmed === '--' ? null : trimmed
}

function numberValue(value: string | undefined) {
  const parsed = Number((value ?? '').replace(/,/g, ''))
  return Number.isFinite(parsed) ? parsed : 0
}

function vinYear(vin: string | null) {
  if (!vin || vin.length < 10) return new Date().getFullYear()
  const codes = 'ABCDEFGHJKLMNPRSTVWXY123456789'
  const index = codes.indexOf(vin[9].toUpperCase())
  if (index < 0) return new Date().getFullYear()
  const year = 2010 + index
  return year > new Date().getFullYear() + 2 ? year - 30 : year
}

function vehicleMake(vin: string | null, assetType: 'truck' | 'trailer') {
  const prefix = vin?.slice(0, 3).toUpperCase() ?? ''
  const makes: Record<string, string> = {
    '1FU': 'Freightliner',
    '3AK': 'Freightliner',
    '4V1': 'Volvo',
    '4V4': 'Volvo',
    '1XK': 'Kenworth',
    '1XP': 'Peterbilt',
    '2HS': 'International',
    '3HS': 'International',
    '1HT': 'International',
    '1UY': 'Utility',
    '1GR': 'Great Dane',
    '1JJ': 'Wabash',
    '5V8': 'Vanguard',
  }
  return makes[prefix] ?? (assetType === 'truck' ? 'Unknown' : 'Unknown')
}

function isTrailer(row: CsvRow, vin: string | null) {
  if (/unpowered|trailer/i.test(row.Name ?? '')) return true
  const prefix = vin?.slice(0, 3).toUpperCase() ?? ''
  return ['1UY', '1GR', '1JJ', '1JJV', '5V8', '1M9', '1A9', '2MN'].some((item) =>
    prefix.startsWith(item)
  )
}

function parseSamsaraDate(value: string | undefined) {
  const cleaned = clean(value)
  if (!cleaned) return null
  const parsed = new Date(`${cleaned} UTC`)
  return Number.isNaN(parsed.getTime()) ? null : parsed
}

function headingDegrees(value: string | undefined) {
  const headings: Record<string, number> = {
    N: 0,
    NE: 45,
    E: 90,
    SE: 135,
    S: 180,
    SW: 225,
    W: 270,
    NW: 315,
  }
  return headings[value?.trim().toUpperCase() ?? ''] ?? null
}

export function normalizeVehicleCsv(csv: string): {
  kind: 'map-assets' | 'samsara-gateways'
  vehicles: ImportedVehicle[]
  skipped: number
} {
  const rows = parseCsv(csv)
  if (rows.length === 0) throw new Error('CSV file has no data rows')

  if ('Asset ID' in rows[0]) {
    const vehicles = rows.flatMap((row) => {
      const externalId = clean(row['Asset ID'])
      if (!externalId) return []
      const yearMatch = externalId.match(/(?:PTLZ|P5)(\d{2})/i)
      const inferredYear = yearMatch ? 2000 + Number(yearMatch[1]) : new Date().getFullYear()
      return [
        {
          source: 'map-assets' as const,
          externalId,
          assetType: 'trailer' as const,
          make: 'Unknown',
          model: 'Trailer',
          year: inferredYear,
          vin: null,
          licensePlate: externalId,
          mileage: numberValue(row['Total Mileage (mi)']),
          trackingAddress: clean(row.Location),
          trackingStatus: clean(row.Status),
          trackingLastSeenAt: new Date(),
          trackingCargoStatus: clean(row['Cargo Status']),
          trackingSpeed: numberValue(row.Speed),
          trackingHeading: headingDegrees(row.Heading),
        },
      ]
    })
    return { kind: 'map-assets', vehicles, skipped: rows.length - vehicles.length }
  }

  if ('Gateway Serial' in rows[0] && 'Name' in rows[0]) {
    const vehicles = rows.flatMap((row) => {
      const externalId = clean(row.Name)
      const gatewaySerial = clean(row['Gateway Serial'])
      if (!externalId || externalId === gatewaySerial) return []

      const vin = clean(row.VIN)
      const assetType: 'truck' | 'trailer' = isTrailer(row, vin) ? 'trailer' : 'truck'
      const plate = clean(row['License Plate'])
      return [
        {
          source: 'samsara-gateways' as const,
          externalId: externalId.replace(/\s+Unpowered$/i, '').trim(),
          assetType,
          make: vehicleMake(vin, assetType),
          model: assetType === 'truck' ? 'Tractor' : 'Trailer',
          year: vinYear(vin),
          vin,
          licensePlate: plate,
          mileage: numberValue(row['Odometer (mi)']),
          trackingAddress: clean(row['Last Location']),
          trackingStatus: null,
          trackingLastSeenAt: parseSamsaraDate(row['Last Connected']),
          trackingCargoStatus: null,
          trackingSpeed: null,
          trackingHeading: null,
        },
      ]
    })
    return { kind: 'samsara-gateways', vehicles, skipped: rows.length - vehicles.length }
  }

  throw new Error('Unsupported CSV format')
}
