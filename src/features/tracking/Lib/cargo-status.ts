export type TrackingCargoStatus = 'empty' | 'loaded' | 'unknown'

type SkyBitzSerial = {
  serialtype?: string
  serialname?: string
  serialdata?: string
}

type SkyBitzCargoSource = {
  serial?: SkyBitzSerial | SkyBitzSerial[]
}

type PremierLegacyCargoSource = {
  cargoOn?: boolean
  cargoLoaded?: boolean
}

function asArray<T>(value: T | T[] | undefined): T[] {
  if (value === undefined) return []
  return Array.isArray(value) ? value : [value]
}

export function normalizeTrackingCargoStatus(value: unknown): TrackingCargoStatus {
  const normalized = String(value ?? '')
    .trim()
    .replace(/^\((.*)\)$/, '$1')
    .toLowerCase()

  if (normalized === 'loaded' || normalized === 'full') return 'loaded'
  if (normalized === 'empty' || normalized === 'unloaded') return 'empty'
  return 'unknown'
}

export function getSkyBitzCargoStatus(source: SkyBitzCargoSource): TrackingCargoStatus {
  const cargoSensor = asArray(source.serial).find((sensor) => {
    const name = sensor.serialname?.trim().toLowerCase()
    return name === 'cargo' || sensor.serialtype?.trim() === '1'
  })

  return normalizeTrackingCargoStatus(cargoSensor?.serialdata)
}

export function getPremierLegacyCargoStatus(source: PremierLegacyCargoSource): TrackingCargoStatus {
  if (source.cargoOn !== true || typeof source.cargoLoaded !== 'boolean') return 'unknown'
  return source.cargoLoaded ? 'loaded' : 'empty'
}
