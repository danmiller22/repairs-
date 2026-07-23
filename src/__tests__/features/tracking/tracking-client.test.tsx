import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { TrackingClient } from '@/features/tracking/Components/tracking-client'
import type { TrackingAsset } from '@/features/tracking/types'

vi.mock('next/navigation', () => ({
  useRouter: () => ({ refresh: vi.fn(), push: vi.fn() }),
}))

vi.mock('@/features/tracking/Components/tracking-map-dynamic', () => ({
  TrackingMap: ({ assets }: { assets: TrackingAsset[] }) => (
    <div data-testid="tracking-map">{assets.map((asset) => asset.id).join(',')}</div>
  ),
}))

const assets: TrackingAsset[] = [
  {
    id: 'truck-1',
    assetType: 'truck',
    make: 'Freightliner',
    model: 'Cascadia',
    year: 2024,
    vin: 'TRUCKVIN',
    licensePlate: 'TRK-101',
    trackingProvider: 'samsara',
    trackingExternalId: 'sam-1',
    trackingLatitude: 41.8781,
    trackingLongitude: -87.6298,
    trackingSpeed: 45,
    trackingHeading: 90,
    trackingStatus: 'moving',
    trackingAddress: 'Chicago, IL',
    trackingLastSeenAt: new Date().toISOString(),
  },
  {
    id: 'trailer-1',
    assetType: 'trailer',
    make: 'Utility',
    model: '3000R',
    year: 2023,
    vin: 'TRAILERVIN',
    licensePlate: 'TRL-202',
    trackingProvider: 'xtralease',
    trackingExternalId: 'xtra-1',
    trackingLatitude: 41.525,
    trackingLongitude: -88.0817,
    trackingSpeed: 0,
    trackingHeading: null,
    trackingStatus: 'stopped',
    trackingAddress: 'Joliet, IL',
    trackingLastSeenAt: new Date().toISOString(),
  },
]

describe('TrackingClient', () => {
  it('shows trucks and trailers together in one tracking view', () => {
    render(<TrackingClient assets={assets} />)

    expect(screen.getByText('TRK-101')).toBeInTheDocument()
    expect(screen.getByText('TRL-202')).toBeInTheDocument()
    expect(screen.getByText('Samsara')).toBeInTheDocument()
    expect(screen.getByText('XTRA Lease')).toBeInTheDocument()
    expect(screen.getByTestId('tracking-map')).toHaveTextContent('truck-1,trailer-1')
  })

  it('filters the unified list to trailers', () => {
    render(<TrackingClient assets={assets} />)

    fireEvent.click(screen.getByRole('button', { name: 'trailers' }))

    expect(screen.queryByText('TRK-101')).not.toBeInTheDocument()
    expect(screen.getByText('TRL-202')).toBeInTheDocument()
    expect(screen.getByTestId('tracking-map')).toHaveTextContent('trailer-1')
  })
})
