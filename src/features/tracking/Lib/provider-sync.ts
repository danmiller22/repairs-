import 'server-only'

import { XMLParser } from 'fast-xml-parser'
import { CompactEncrypt, importJWK } from 'jose'
import { db } from '@/lib/db'
import type {
  PremierCredentials,
  SamsaraCredentials,
  TrackingProviderId,
  XtraLeaseCredentials,
} from './provider-credentials'
import {
  getPremierLegacyCargoStatus,
  getSkyBitzCargoStatus,
  type TrackingCargoStatus,
} from './cargo-status'

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
  dwellSince: Date | null
  cargoStatus: TrackingCargoStatus
  mileage: number | null
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
        dwellSince: null,
        cargoStatus: 'unknown',
        mileage: null,
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
  serial?:
    | {
        serialtype?: string
        serialname?: string
        serialdata?: string
      }
    | Array<{
        serialtype?: string
        serialname?: string
        serialdata?: string
      }>
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
        dwellSince: null,
        cargoStatus: getSkyBitzCargoStatus(position),
        mileage: null,
      },
    ]
  })
}

type PremierAsset = {
  id?: string
  name?: string
  active?: boolean
  type?: string
  year?: number | string
  vin?: string
  make?: string
  model?: string
  cargoStatus?: { cargoLoaded?: boolean } | string
  location?: {
    lat?: number
    lng?: number
    locationLastReported?: string
  }
  address?: {
    line1?: string
    city?: string
    stateOrProvince?: string
    postalCode?: string
  }
  direction?: string | number
  distanceDriven?: number
  eventTime?: string
  odometer?: number
  speed?: number
  status?: string
  statusStartDate?: string
}

type PremierAssetsPage = {
  content?: PremierAsset[]
  total?: number
}

const PREMIER_AUTH_URL = 'https://auth-service.spireon.com'
const PREMIER_ASSETS_URL = 'https://ati-avs-api.spireon.com/api/v1/assets'
const PREMIER_TRANSPORTATION_URL = 'https://transportation.us.spireon.com'

type PremierLegacyAsset = {
  assetName?: string
  assetDisplayName?: string
  cargoOn?: boolean
  cargoLoaded?: boolean
}

type PremierLegacyAssetPage = {
  success?: boolean
  data?: PremierLegacyAsset[]
  total?: number
}

function compassHeading(value: unknown) {
  if (typeof value === 'number') return safeNumber(value)
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
  return (
    headings[
      String(value || '')
        .trim()
        .toUpperCase()
    ] ?? null
  )
}

function formatPremierAddress(address: PremierAsset['address']) {
  if (!address) return null
  const locality = [address.city, address.stateOrProvince, address.postalCode]
    .filter(Boolean)
    .join(', ')
  return [address.line1, locality].filter(Boolean).join(', ') || null
}

async function getPremierToken(credentials: PremierCredentials) {
  const jwkResponse = await fetch(`${PREMIER_AUTH_URL}/rest/jwe/latest-jwk`, {
    cache: 'no-store',
    signal: AbortSignal.timeout(20_000),
  })
  if (!jwkResponse.ok) {
    throw new Error(`Premier/Spireon authentication setup failed (${jwkResponse.status})`)
  }

  const jwkDto = (await jwkResponse.json()) as { id?: string; jwk?: string }
  if (!jwkDto.id || !jwkDto.jwk) {
    throw new Error('Premier/Spireon returned an invalid encryption key')
  }

  const key = await importJWK(JSON.parse(jwkDto.jwk), 'RSA-OAEP-256')
  const encryptedCredentials = await new CompactEncrypt(
    new TextEncoder().encode(
      JSON.stringify({ username: credentials.username, password: credentials.password })
    )
  )
    .setProtectedHeader({ alg: 'RSA-OAEP-256', enc: 'A256GCM', kid: jwkDto.id })
    .encrypt(key)

  const response = await fetch(`${PREMIER_AUTH_URL}/rest/loginRequest?clientId=atiWeb`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: encryptedCredentials,
    cache: 'no-store',
    signal: AbortSignal.timeout(30_000),
  })
  const payload = (await response.json().catch(() => null)) as {
    authResult?: { token?: string; scope?: string }
    challenge?: string | null
  } | null

  if (!response.ok || !payload?.authResult?.token) {
    if (response.status === 401 || response.status === 403) {
      throw new Error('Premier/Spireon rejected the username or password')
    }
    throw new Error(`Premier/Spireon sign-in failed (${response.status})`)
  }
  return payload.authResult.token
}

function getResponseCookies(response: Response) {
  const headers = response.headers as Headers & { getSetCookie?: () => string[] }
  const setCookies = headers.getSetCookie?.() ?? []
  return setCookies
    .map((value) => value.split(';', 1)[0]?.trim())
    .filter((value): value is string => Boolean(value))
    .join('; ')
}

async function fetchPremierLegacyCargo(token: string) {
  const loginResponse = await fetch(
    `${PREMIER_TRANSPORTATION_URL}/home/login?apiToken=${encodeURIComponent(token)}`,
    {
      redirect: 'manual',
      cache: 'no-store',
      signal: AbortSignal.timeout(30_000),
    }
  )
  const redirectLocation = loginResponse.headers.get('location')
  const sessionId = redirectLocation?.match(/;jsessionid=([^/?#]+)/i)?.[1]
  const cookies = getResponseCookies(loginResponse)

  if (
    loginResponse.status < 300 ||
    loginResponse.status >= 400 ||
    !redirectLocation ||
    !sessionId ||
    !cookies
  ) {
    throw new Error('Premier/Spireon could not open the FleetLocate cargo feed')
  }

  const url = new URL(
    `/rest/json/assetGrid;jsessionid=${encodeURIComponent(sessionId)}`,
    PREMIER_TRANSPORTATION_URL
  )
  url.searchParams.set('offset', '0')
  url.searchParams.set('max', '1000')

  const response = await fetch(url, {
    headers: {
      Accept: 'application/json',
      Cookie: cookies,
      Referer: redirectLocation,
    },
    redirect: 'manual',
    cache: 'no-store',
    signal: AbortSignal.timeout(45_000),
  })
  if (!response.ok || response.status >= 300) {
    throw new Error(`Premier/Spireon cargo request failed (${response.status})`)
  }

  const payload = (await response.json()) as PremierLegacyAssetPage
  if (payload.success === false || !Array.isArray(payload.data)) {
    throw new Error('Premier/Spireon returned an unreadable cargo response')
  }

  return new Map(
    payload.data.flatMap((asset) => {
      const externalId = asset.assetName?.trim() || asset.assetDisplayName?.trim()
      const cargoStatus = getPremierLegacyCargoStatus(asset)
      return externalId && cargoStatus !== 'unknown'
        ? ([[externalId, cargoStatus]] as Array<[string, TrackingCargoStatus]>)
        : []
    })
  )
}

async function fetchPremierUnits(
  credentials: PremierCredentials
): Promise<NormalizedTrackingUnit[]> {
  const token = await getPremierToken(credentials)
  const legacyCargoByAsset = await fetchPremierLegacyCargo(token)
  const assets: PremierAsset[] = []
  const limit = 250

  for (let offset = 0; offset < 10_000; offset += limit) {
    const url = new URL(PREMIER_ASSETS_URL)
    url.searchParams.set('limit', String(limit))
    url.searchParams.set('offset', String(offset))
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${token}` },
      cache: 'no-store',
      signal: AbortSignal.timeout(45_000),
    })
    if (!response.ok) {
      throw new Error(`Premier/Spireon asset request failed (${response.status})`)
    }

    const page = (await response.json()) as PremierAssetsPage
    const content = page.content ?? []
    assets.push(...content)
    if (content.length < limit || assets.length >= (page.total ?? 0)) break
  }

  return assets.flatMap((asset) => {
    const externalId = asset.name?.trim() || asset.id?.trim()
    if (!externalId) return []
    const latitude = safeNumber(asset.location?.lat)
    const longitude = safeNumber(asset.location?.lng)
    const speed = safeNumber(asset.speed)
    const rawStatus = asset.status?.trim().toLowerCase()
    const status =
      latitude === null || longitude === null
        ? 'offline'
        : rawStatus === 'moving' || (speed ?? 0) > 2
          ? 'moving'
          : rawStatus === 'idle'
            ? 'idle'
            : 'stopped'
    const cargoLoaded =
      typeof asset.cargoStatus === 'object' ? asset.cargoStatus.cargoLoaded : undefined
    const year = safeNumber(asset.year)
    const odometerMeters = safeNumber(asset.odometer ?? asset.distanceDriven)

    return [
      {
        externalId,
        assetType: 'trailer',
        make: asset.make?.trim() || 'Premier Trailer',
        model: asset.model?.trim() || asset.type?.trim() || 'Semi-Trailer',
        year: year && year >= 1900 && year <= 2200 ? Math.round(year) : new Date().getFullYear(),
        vin: asset.vin?.trim() || null,
        licensePlate: externalId,
        latitude,
        longitude,
        speed,
        heading: compassHeading(asset.direction),
        status,
        address: formatPremierAddress(asset.address),
        lastSeenAt: safeDate(asset.location?.locationLastReported || asset.eventTime),
        dwellSince: status === 'moving' ? null : safeDate(asset.statusStartDate),
        cargoStatus:
          legacyCargoByAsset.get(externalId) ??
          (cargoLoaded === true ? 'loaded' : cargoLoaded === false ? 'empty' : 'unknown'),
        mileage:
          odometerMeters === null ? null : Math.max(0, Math.round(odometerMeters / 1609.344)),
      },
    ]
  })
}

function sameStopLocation(
  existing: { trackingLatitude: number | null; trackingLongitude: number | null },
  unit: NormalizedTrackingUnit
) {
  if (
    existing.trackingLatitude === null ||
    existing.trackingLongitude === null ||
    unit.latitude === null ||
    unit.longitude === null
  ) {
    return false
  }
  return (
    Math.abs(existing.trackingLatitude - unit.latitude) < 0.003 &&
    Math.abs(existing.trackingLongitude - unit.longitude) < 0.003
  )
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
      trackingLatitude: true,
      trackingLongitude: true,
      trackingStatus: true,
      trackingStoppedSince: true,
      trackingCargoStatus: true,
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
    const isStopped = unit.status === 'stopped' || unit.status === 'idle'
    const trackingStoppedSince = !isStopped
      ? null
      : unit.dwellSince ||
        (match &&
        (match.trackingStatus === 'stopped' || match.trackingStatus === 'idle') &&
        match.trackingStoppedSince &&
        sameStopLocation(match, unit)
          ? match.trackingStoppedSince
          : new Date())
    const cargoStatus =
      unit.cargoStatus === 'unknown'
        ? ((match?.trackingCargoStatus as TrackingCargoStatus | null) ?? 'unknown')
        : unit.cargoStatus
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
      trackingStoppedSince,
      trackingCargoStatus: cargoStatus,
    }

    if (match) {
      return db.vehicle.update({
        where: { id: match.id },
        data: {
          ...trackingData,
          make: unit.make,
          model: unit.model,
          year: unit.year,
          vin: unit.vin ?? undefined,
          licensePlate: unit.licensePlate ?? undefined,
          mileage: unit.mileage ?? undefined,
        },
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
        mileage: unit.mileage ?? 0,
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
  credentials: SamsaraCredentials | XtraLeaseCredentials | PremierCredentials
  organizationId: string
  userId: string
}) {
  const units =
    args.provider === 'samsara'
      ? await fetchSamsaraUnits(args.credentials as SamsaraCredentials)
      : args.provider === 'xtralease'
        ? await fetchXtraLeaseUnits(args.credentials as XtraLeaseCredentials)
        : await fetchPremierUnits(args.credentials as PremierCredentials)

  return persistUnits(args.provider, args.organizationId, args.userId, units)
}
