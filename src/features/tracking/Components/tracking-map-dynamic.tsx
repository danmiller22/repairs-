'use client'

import dynamic from 'next/dynamic'
import type { TrackingAsset } from '../types'

const TrackingMapInner = dynamic(() => import('./tracking-map'), {
  ssr: false,
  loading: () => (
    <div className="flex h-full min-h-[360px] items-center justify-center bg-muted/30 text-sm text-muted-foreground">
      Loading map…
    </div>
  ),
})

export function TrackingMap({ assets }: { assets: TrackingAsset[] }) {
  return <TrackingMapInner assets={assets} />
}
