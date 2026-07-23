import { PageHeader } from '@/components/page-header'
import {
  getTrackingAssets,
  getTrackingConnections,
} from '@/features/tracking/Actions/trackingActions'
import { TrackingClient } from '@/features/tracking/Components/tracking-client'
import type { TrackingAsset, TrackingConnection } from '@/features/tracking/types'

export default async function TrackingPage() {
  const [result, connectionResult] = await Promise.all([
    getTrackingAssets(),
    getTrackingConnections(),
  ])

  if (!result.success || !result.data) {
    return (
      <>
        <PageHeader />
        <div className="flex h-[50vh] items-center justify-center">
          <p className="text-muted-foreground">{result.error || 'Could not load tracking'}</p>
        </div>
      </>
    )
  }

  const assets: TrackingAsset[] = result.data.map((asset) => ({
    ...asset,
    assetType: asset.assetType === 'trailer' ? 'trailer' : 'truck',
    trackingLastSeenAt: asset.trackingLastSeenAt?.toISOString() ?? null,
    trackingStoppedSince: asset.trackingStoppedSince?.toISOString() ?? null,
  }))
  const connections: TrackingConnection[] =
    connectionResult.success && connectionResult.data ? connectionResult.data : []

  return (
    <>
      <PageHeader />
      <div className="flex flex-1 flex-col gap-4 p-4 pt-0">
        <TrackingClient assets={assets} connections={connections} />
      </div>
    </>
  )
}
