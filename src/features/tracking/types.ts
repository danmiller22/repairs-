export type TrackingAsset = {
  id: string
  assetType: 'truck' | 'trailer'
  make: string
  model: string
  year: number
  vin: string | null
  licensePlate: string | null
  trackingProvider: string | null
  trackingExternalId: string | null
  trackingLatitude: number | null
  trackingLongitude: number | null
  trackingSpeed: number | null
  trackingHeading: number | null
  trackingStatus: string | null
  trackingAddress: string | null
  trackingLastSeenAt: string | null
}

export type TrackingConnection = {
  id: 'samsara' | 'xtralease' | 'premier'
  name: string
  scope: string
  configured: boolean
  available: boolean
  source: 'secure-settings' | 'environment' | null
  lastSyncedAt: string | null
  assetCount: number
  error: string | null
}
