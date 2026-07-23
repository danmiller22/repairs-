'use client'

import { useEffect, useMemo } from 'react'
import L, { type LatLngBoundsExpression } from 'leaflet'
import { MapContainer, Marker, Popup, TileLayer, useMap } from 'react-leaflet'
import type { TrackingAsset } from '../types'

function FitAssets({ assets }: { assets: TrackingAsset[] }) {
  const map = useMap()

  useEffect(() => {
    const positions = assets
      .filter((asset) => asset.trackingLatitude !== null && asset.trackingLongitude !== null)
      .map((asset) => [asset.trackingLatitude!, asset.trackingLongitude!] as [number, number])

    if (positions.length === 1) {
      map.setView(positions[0], 12)
    } else if (positions.length > 1) {
      map.fitBounds(positions as LatLngBoundsExpression, { padding: [40, 40] })
    }
  }, [assets, map])

  return null
}

export default function TrackingMapInner({ assets }: { assets: TrackingAsset[] }) {
  const locatedAssets = assets.filter(
    (asset) => asset.trackingLatitude !== null && asset.trackingLongitude !== null
  )

  const icons = useMemo(
    () => ({
      truck: L.divIcon({
        className: '',
        html: '<div class="tracking-marker tracking-marker-truck">T</div>',
        iconSize: [34, 34],
        iconAnchor: [17, 17],
      }),
      trailer: L.divIcon({
        className: '',
        html: '<div class="tracking-marker tracking-marker-trailer">R</div>',
        iconSize: [34, 34],
        iconAnchor: [17, 17],
      }),
    }),
    []
  )

  return (
    <div className="relative h-full min-h-[360px] overflow-hidden">
      <MapContainer
        center={[41.8781, -87.6298]}
        zoom={9}
        scrollWheelZoom
        className="h-full min-h-[360px] w-full"
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap contributors</a>'
          url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <FitAssets assets={locatedAssets} />
        {locatedAssets.map((asset) => (
          <Marker
            key={asset.id}
            position={[asset.trackingLatitude!, asset.trackingLongitude!]}
            icon={icons[asset.assetType]}
          >
            <Popup>
              <div className="min-w-44">
                <strong>{asset.licensePlate || `${asset.year} ${asset.make}`}</strong>
                <br />
                {asset.year} {asset.make} {asset.model}
                <br />
                <span>{asset.trackingAddress || 'Location available'}</span>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
      {locatedAssets.length === 0 && (
        <div className="pointer-events-none absolute inset-x-4 top-4 z-[500] rounded-lg border bg-background/95 p-3 text-sm shadow-sm backdrop-blur">
          Add a location manually or connect a tracking provider to place trucks and trailers on the
          map.
        </div>
      )}
    </div>
  )
}
