import 'server-only'

import { XMLParser } from 'fast-xml-parser'
import { db } from '@/lib/db'
import type {
  SamsaraCredentials,
  TrackingProviderId,
  XtraLeaseCredentials,
} from './provider-credentials'

type NormalizedTrackingUnit = {
  externalId: string
  assetType: 'truck' | 'trailer'
  make: string
  model: string
  year: number
  vin: string | null
  licensePlate: string | null
  latitude: number | null
  longitude: number | null
  speed: number | null
  heading: number | null
  status: string
  address: string | null
  lastSeenAt: Date | null
}

type SamsaraVehicle = {
  id?: string
  name?: string
  vin?: string
  make?: string
  model?: string
  year?: string | number
  licensePlate?: string
}

type SamsaraLocation = {
  id?: string
  vehicleId?: string
  name?: string
  latitude?: number
  longitude?: number
  heading?: number
  headingDegrees?: number
  speed?: number
  speedMilesPerHour?: number
  time?: string
  reverseGeo?: { formattedLocation?: string }
  location?: SamsaraLocation
  gps?: Array<{ time?: string; value?: SamsaraLocation }>
}

type SamsaraPage<T> = {
  data?: T[]
  pagination?: {
    endCursor?: string
    hasNextPage?: boolean
  }
}

function safeNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === '') return null
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : null
}

function safeDate(value: unknown): Date | null {
  if (!value) return null
  const text = String(value).trim()
  const normalized = /^\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}$/.test(text)
    ? `${text.replaceAll('/', '-').replace(' ', 'T')}Z`
    : text
  const parsed = new Date(normalized)
  return Number.isNaN(parsed.getTime()) ? null : parsed
}

async function fetchSamsaraPages<T>(path: string, apiKey: string) {
  const items: T[] = []
  let cursor: string | undefined

  for (let page = 0; page < 50; page += 1) {
    const url = new URL(path, 'https://api.samsara.com')
    if (cursor) url.searchParams.set('after', cursor)
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${apiKey}` },
      cache: 'no-store',
      signal: AbortSignal.timeout(30_000),
    })

    if (!response.ok) {
      if (response.status === 401) {
        throw new Error('Samsara rejected the API token (401). Replace it and try again.')
      }
      if (response.status === 403) {
        throw new Error('Samsara token needs Read Vehicles and Read Vehicle Statistics access.')
      }
      throw new Error(`Samsara request failed (${response.status})`)
    }

    const payload = (await response.json()) as SamsaraPage<T>
    items.push(...(payload.data ?? []))
    if (!payload.pagination?.hasNextPage || !payload.pagination.endCursor) break
    cursor = payload.pagination.endCursor
  }

  return items
}

async function fetchSamsaraUnits(
  credentials: SamsaraCredentials
): Promise<NormalizedTrackingUnit[]> {
  const [vehicles, locations] = await Promise.all([
    fetchSamsaraPages<SamsaraVehicle>('/fleet/vehicles', credentials.apiKey),
    fetchSamsaraPages<SamsaraLocation>('/fleet/vehicles/locations', credentials.apiKey),
  ])

  const locationById = new Map(
    locations
      .map((location) => [String(location.id || location.vehicleId || ''), location] as const)
      .filter(([id]) => id)
  )

  return vehicles.flatMap((vehicle) => {
    if (!vehicle.id) return []
    const rawLocation = locationById.get(String(vehicle.id))
    const point = rawLocation?.location || rawLocation?.gps?.at(-1)?.value || rawLocation
    const speed = safeNumber(point?.speedMilesPerHour ?? point?.speed)
    const latitude = safeNumber(point?.latitude)
    const longitude = safeNumber(point?.longitude)
    const year = safeNumber(vehicle.year)

    return [
      {
        externalId: String(vehicle.id),
        assetType: 'truck',
        make: vehicle.make?.trim() || 'Truck',
        model: vehicle.model?.trim() || vehicle.name?.trim() || 'Samsara Unit',
        year: year && year >= 1900 && year <= 2200 ? Math.round(year) : new Date().getFullYear(),
        vin: vehicle.vin?.trim() || null,
        licensePlate: vehicle.licensePlate?.trim() || vehicle.name?.trim() || null,
        latitude,
        longitude,
        speed,
        heading: safeNumber(point?.headingDegrees ?? point?.heading),
        status:
          latitude === null || longitude === null
            ? 'offline'
            : (speed ?? 0) > 2
              ? 'moving'
              : 'stopped',
        address: point?.reverseGeo?.formattedLocation?.trim() || null,
        lastSeenAt: safeDate(rawLocation?.gps?.at(-1)?.time || point?.time || rawLocation?.time),
      },
    ]
  })
}

function asArray<T>(value: T | T[] | undefined): T[] {
  if (value === undefined) return []
  return Array.isArray(value) ? value : [value]
}

type SkyBitzGls = {
  mtsn?: string
  asset?: {
    assetid?: string
    assettype?: string
    secondaryid?: string
  }
  latitude?: string
  longitude?: string
  speed?: string
  headingindegrees?: string
  time?: string
  messagereceivedtime?: string
  landmark?: {
    geoname?: string
    state?: string
    country?: string
    distance?: string
    direction?: string
  }
  idle?: {
    idlestatus?: string
  }
}

function formatSkyBitzAddress(landmark: SkyBitzGls['landmark']) {
  if (!landmark) return null
  const place = [landmark.geoname, landmark.state, landmark.country].filter(Boolean).join(', ')
  const distance = [
    landmark.distance && `${landmark.distance} mi`,
    landmark.direction,
    place && `from ${place}`,
  ]
    .filter(Boolean)
    .join(' ')
  return distance || place || null
}

async function fetchXtraLeaseUnits(
  credentials: XtraLeaseCredentials
): Promise<NormalizedTrackingUnit[]> {
  const url = new URL(
    'QueryPositions',
    credentials.serviceUrl.endsWith('/') ? credentials.serviceUrl : `${credentials.serviceUrl}/`
  )
  url.searchParams.set('assetid', 'ALL')
  url.searchParams.set('customer', credentials.username)
  url.searchParams.set('password', credentials.password)
  url.searchParams.set('version', credentials.apiVersion)
  url.searchParams.set('sortby', '1')

  const response = await fetch(url, {
    cache: 'no-store',
    signal: AbortSignal.timeout(75_000),
  })
  if (!response.ok) throw new Error(`XTRA Lease/SkyBitz request failed (${response.status})`)

  const xml = await response.text()
  if (xml.length > 15_000_000) throw new Error('XTRA Lease response is unexpectedly large')

  const parser = new XMLParser({
    ignoreAttributes: false,
    processEntities: false,
    parseTagValue: false,
    trimValues: true,
  })
  const parsed = parser.parse(xml) as {
    skybitz?: { error?: string; gls?: SkyBitzGls | SkyBitzGls[] }
    SkyBitz?: { error?: string; gls?: SkyBitzGls | SkyBitzGls[] }
  }
  const root = parsed.skybitz || parsed.SkyBitz
  if (!root) throw new Error('XTRA Lease returned an unreadable response')
  if (String(root.error ?? '0').trim() !== '0') {
    throw new Error(`XTRA Lease/SkyBitz returned error ${String(root.error).trim()}`)
  }

  return asArray(root.gls).flatMap((position) => {
    const externalId = position.asset?.assetid?.trim() || position.mtsn?.trim()
    if (!externalId) return []
    const latitude = safeNumber(position.latitude)
    const longitude = safeNumber(position.longitude)
    const speed = safeNumber(position.speed)
    const idleStatus = position.idle?.idlestatus?.trim().toLowerCase()

    return [
      {
        externalId,
        assetType: 'trailer',
        make: 'XTRA Lease',
        model: position.asset?.assettype?.trim() || 'Semi-Trailer',
        year: new Date().getFullYear(),
        vin: null,
        licensePlate: position.asset?.secondaryid?.trim() || externalId,
        latitude,
        longitude,
        speed,
        heading: safeNumber(position.headingindegrees),
        status:
          latitude === null || longitude === null
            ? 'offline'
            : (speed ?? 0) > 2
              ? 'moving'
              : idleStatus === 'idle'
                ? 'idle'
                : 'stopped',
        address: formatSkyBitzAddress(position.landmark),
        lastSeenAt: safeDate(position.messagereceivedtime || position.time),
      },
    ]
  })
}

async function persistUnits(
  provider: TrackingProviderId,
  organizationId: string,
  userId: string,
  units: NormalizedTrackingUnit[]
) {
  const existing = await db.vehicle.findMany({
    where: { organizationId },
    select: {
      id: true,
      vin: true,
      licensePlate: true,
      trackingProvider: true,
      trackingExternalId: true,
    },
  })

  const byExternalId = new Map(
    existing
      .filter((vehicle) => vehicle.trackingProvider === provider && vehicle.trackingExternalId)
      .map((vehicle) => [vehicle.trackingExternalId!, vehicle])
  )
  const byVin = new Map(
    existing
      .filter((vehicle) => vehicle.vin)
      .map((vehicle) => [vehicle.vin!.toUpperCase(), vehicle])
  )
  const byPlate = new Map(
    existing
      .filter((vehicle) => vehicle.licensePlate)
      .map((vehicle) => [vehicle.licensePlate!.toUpperCase(), vehicle])
  )

  const operations = units.map((unit) => {
    const match =
      byExternalId.get(unit.externalId) ||
      (unit.vin ? byVin.get(unit.vin.toUpperCase()) : undefined) ||
      (unit.licensePlate ? byPlate.get(unit.licensePlate.toUpperCase()) : undefined)
    const trackingData = {
      assetType: unit.assetType,
      trackingProvider: provider,
      trackingExternalId: unit.externalId,
      trackingLatitude: unit.latitude,
      trackingLongitude: unit.longitude,
      trackingSpeed: unit.speed,
      trackingHeading: unit.heading,
      trackingStatus: unit.status,
      trackingAddress: unit.address,
      trackingLastSeenAt: unit.lastSeenAt,
    }

    if (match) {
      return db.vehicle.update({
        where: { id: match.id },
        data: trackingData,
      })
    }

    return db.vehicle.create({
      data: {
        ...trackingData,
        make: unit.make,
        model: unit.model,
        year: unit.year,
        vin: unit.vin,
        licensePlate: unit.licensePlate,
        fuelType: unit.assetType === 'truck' ? 'diesel' : 'other',
        userId,
        organizationId,
      },
    })
  })

  if (operations.length) await db.$transaction(operations)
  return operations.length
}

export async function syncProviderUnits(args: {
  provider: TrackingProviderId
  credentials: SamsaraCredentials | XtraLeaseCredentials
  organizationId: string
  userId: string
}) {
  const units =
    args.provider === 'samsara'
      ? await fetchSamsaraUnits(args.credentials as SamsaraCredentials)
      : await fetchXtraLeaseUnits(args.credentials as XtraLeaseCredentials)

  return persistUnits(args.provider, args.organizationId, args.userId, units)
}
