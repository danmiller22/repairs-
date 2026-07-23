'use client'

import { useMemo, useState, useTransition } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import {
  Container,
  ExternalLink,
  Link2,
  MapPin,
  Pencil,
  Plus,
  Radio,
  Search,
  Truck,
} from 'lucide-react'
import { toast } from 'sonner'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { cn } from '@/lib/utils'
import { updateManualTrackingLocation } from '../Actions/trackingActions'
import type { TrackingAsset } from '../types'
import { TrackingMap } from './tracking-map-dynamic'

const providers = [
  { id: 'samsara', name: 'Samsara', scope: 'Trucks & trailers' },
  { id: 'xtralease', name: 'XTRA Lease', scope: 'Trailers' },
  { id: 'premier', name: 'Premier Trailer', scope: 'Trailers' },
] as const

const statusStyles: Record<string, string> = {
  moving: 'border-emerald-500/25 bg-emerald-500/10 text-emerald-500',
  stopped: 'border-blue-500/25 bg-blue-500/10 text-blue-500',
  idle: 'border-amber-500/25 bg-amber-500/10 text-amber-500',
  maintenance: 'border-violet-500/25 bg-violet-500/10 text-violet-500',
  offline: 'border-muted bg-muted text-muted-foreground',
}

function formatLastSeen(value: string | null) {
  if (!value) return 'Never'
  const date = new Date(value)
  const diffMinutes = Math.max(0, Math.floor((Date.now() - date.getTime()) / 60000))
  if (diffMinutes < 1) return 'Just now'
  if (diffMinutes < 60) return `${diffMinutes}m ago`
  if (diffMinutes < 1440) return `${Math.floor(diffMinutes / 60)}h ago`
  return date.toLocaleDateString()
}

export function TrackingClient({ assets }: { assets: TrackingAsset[] }) {
  const router = useRouter()
  const [filter, setFilter] = useState<'all' | 'truck' | 'trailer'>('all')
  const [search, setSearch] = useState('')
  const [editing, setEditing] = useState<TrackingAsset | null>(null)
  const [isPending, startTransition] = useTransition()

  const filteredAssets = useMemo(() => {
    const query = search.trim().toLowerCase()
    return assets.filter((asset) => {
      if (filter !== 'all' && asset.assetType !== filter) return false
      if (!query) return true
      return [asset.licensePlate, asset.vin, asset.make, asset.model, asset.trackingAddress].some(
        (value) => value?.toLowerCase().includes(query)
      )
    })
  }, [assets, filter, search])

  const trucks = assets.filter((asset) => asset.assetType === 'truck').length
  const trailers = assets.filter((asset) => asset.assetType === 'trailer').length
  const located = assets.filter(
    (asset) => asset.trackingLatitude !== null && asset.trackingLongitude !== null
  ).length

  const saveLocation = (formData: FormData) => {
    if (!editing) return
    startTransition(async () => {
      const result = await updateManualTrackingLocation({
        vehicleId: editing.id,
        latitude: formData.get('latitude'),
        longitude: formData.get('longitude'),
        speed: formData.get('speed') || undefined,
        status: formData.get('status'),
        address: formData.get('address') || undefined,
      })

      if (result.success) {
        toast.success('Location updated')
        setEditing(null)
        router.refresh()
      } else {
        toast.error(result.error || 'Could not update location')
      }
    })
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-semibold tracking-tight">Fleet Tracking</h1>
            <Badge className="border-primary/25 bg-primary/10 text-primary" variant="outline">
              Integration ready
            </Badge>
          </div>
          <p className="mt-1 text-sm text-muted-foreground">
            Trucks and trailers in one live operational view.
          </p>
        </div>
        <Button asChild>
          <Link href="/vehicles?create=true">
            <Plus className="mr-1.5 h-4 w-4" />
            Add Unit
          </Link>
        </Button>
      </div>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        {[
          { label: 'All units', value: assets.length, icon: Radio },
          { label: 'Trucks', value: trucks, icon: Truck },
          { label: 'Trailers', value: trailers, icon: Container },
          { label: 'Located now', value: located, icon: MapPin },
        ].map(({ label, value, icon: Icon }) => (
          <Card key={label} className="border-0 py-4 shadow-sm">
            <CardContent className="flex items-center justify-between px-4">
              <div>
                <p className="text-xs text-muted-foreground">{label}</p>
                <p className="mt-1 text-2xl font-semibold">{value}</p>
              </div>
              <div className="rounded-lg bg-primary/10 p-2.5 text-primary">
                <Icon className="h-5 w-5" />
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-4 xl:grid-cols-[minmax(0,2fr)_minmax(280px,1fr)]">
        <Card className="overflow-hidden border-0 py-0 shadow-sm">
          <div className="h-[430px]">
            <TrackingMap assets={filteredAssets} />
          </div>
        </Card>

        <Card className="border-0 shadow-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <Link2 className="h-4 w-4 text-primary" />
              Tracking connections
            </CardTitle>
            <p className="text-xs text-muted-foreground">
              Provider feeds will merge into the same truck and trailer list.
            </p>
          </CardHeader>
          <CardContent className="space-y-3">
            {providers.map((provider) => (
              <div
                key={provider.id}
                className="flex items-center justify-between rounded-lg border p-3"
              >
                <div>
                  <p className="text-sm font-medium">{provider.name}</p>
                  <p className="text-xs text-muted-foreground">{provider.scope}</p>
                </div>
                <Badge variant="outline" className="border-primary/20 bg-primary/5 text-primary">
                  Ready
                </Badge>
              </div>
            ))}
            <div className="rounded-lg bg-muted/60 p-3 text-xs text-muted-foreground">
              API credentials are not required yet. Until the integrations are connected, managers
              can update a unit location manually.
            </div>
          </CardContent>
        </Card>
      </div>

      <Card className="border-0 shadow-sm">
        <CardHeader className="gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <CardTitle className="text-base">All tracked units</CardTitle>
            <p className="text-xs text-muted-foreground">One list for trucks and trailers</p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row">
            <div className="flex rounded-lg border p-1">
              {(['all', 'truck', 'trailer'] as const).map((value) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => setFilter(value)}
                  className={cn(
                    'rounded-md px-3 py-1 text-xs font-medium capitalize transition-colors',
                    filter === value
                      ? 'bg-primary text-primary-foreground'
                      : 'text-muted-foreground hover:text-foreground'
                  )}
                >
                  {value === 'all' ? 'All' : `${value}s`}
                </button>
              ))}
            </div>
            <div className="relative">
              <Search className="absolute left-2.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={search}
                onChange={(event) => setSearch(event.target.value)}
                placeholder="Search unit, VIN, location…"
                className="w-full pl-9 sm:w-64"
              />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="overflow-hidden rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Unit</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Provider</TableHead>
                  <TableHead>Last location</TableHead>
                  <TableHead>Updated</TableHead>
                  <TableHead className="w-12" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredAssets.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-32 text-center text-muted-foreground">
                      {assets.length === 0
                        ? 'No units yet. Add a truck or trailer in Fleet and it will appear here automatically.'
                        : 'No units match this filter.'}
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredAssets.map((asset) => {
                    const status = asset.trackingStatus || 'offline'
                    return (
                      <TableRow key={asset.id}>
                        <TableCell>
                          <Link
                            href={`/vehicles/${asset.id}`}
                            className="font-medium hover:text-primary"
                          >
                            {asset.licensePlate || `${asset.year} ${asset.make}`}
                          </Link>
                          <p className="text-xs text-muted-foreground">
                            {asset.year} {asset.make} {asset.model}
                          </p>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-1.5 capitalize">
                            {asset.assetType === 'truck' ? (
                              <Truck className="h-4 w-4 text-primary" />
                            ) : (
                              <Container className="h-4 w-4 text-primary" />
                            )}
                            {asset.assetType}
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge
                            variant="outline"
                            className={cn('capitalize', statusStyles[status])}
                          >
                            {status}
                          </Badge>
                        </TableCell>
                        <TableCell className="capitalize">
                          {asset.trackingProvider || 'Not connected'}
                        </TableCell>
                        <TableCell className="max-w-64">
                          {asset.trackingLatitude !== null && asset.trackingLongitude !== null ? (
                            <a
                              href={`https://www.openstreetmap.org/?mlat=${asset.trackingLatitude}&mlon=${asset.trackingLongitude}#map=15/${asset.trackingLatitude}/${asset.trackingLongitude}`}
                              target="_blank"
                              rel="noreferrer"
                              className="inline-flex items-center gap-1 truncate hover:text-primary"
                            >
                              {asset.trackingAddress ||
                                `${asset.trackingLatitude.toFixed(4)}, ${asset.trackingLongitude.toFixed(4)}`}
                              <ExternalLink className="h-3 w-3 shrink-0" />
                            </a>
                          ) : (
                            <span className="text-muted-foreground">No location</span>
                          )}
                        </TableCell>
                        <TableCell className="text-muted-foreground">
                          {formatLastSeen(asset.trackingLastSeenAt)}
                        </TableCell>
                        <TableCell>
                          <Button
                            variant="ghost"
                            size="icon"
                            aria-label="Update location"
                            onClick={() => setEditing(asset)}
                          >
                            <Pencil className="h-4 w-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    )
                  })
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      <Dialog open={!!editing} onOpenChange={(open) => !open && setEditing(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Update unit location</DialogTitle>
            <DialogDescription>
              Manual positions use the same fields that Samsara, XTRA Lease and Premier Trailer will
              update automatically.
            </DialogDescription>
          </DialogHeader>
          {editing && (
            <form action={saveLocation} className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-2">
                  <Label htmlFor="latitude">Latitude</Label>
                  <Input
                    id="latitude"
                    name="latitude"
                    type="number"
                    step="any"
                    required
                    defaultValue={editing.trackingLatitude ?? ''}
                    placeholder="41.8781"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="longitude">Longitude</Label>
                  <Input
                    id="longitude"
                    name="longitude"
                    type="number"
                    step="any"
                    required
                    defaultValue={editing.trackingLongitude ?? ''}
                    placeholder="-87.6298"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-2">
                  <Label htmlFor="status">Status</Label>
                  <Select name="status" defaultValue={editing.trackingStatus || 'stopped'}>
                    <SelectTrigger id="status">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="moving">Moving</SelectItem>
                      <SelectItem value="stopped">Stopped</SelectItem>
                      <SelectItem value="idle">Idle</SelectItem>
                      <SelectItem value="maintenance">Maintenance</SelectItem>
                      <SelectItem value="offline">Offline</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="speed">Speed (mph)</Label>
                  <Input
                    id="speed"
                    name="speed"
                    type="number"
                    min="0"
                    max="200"
                    defaultValue={editing.trackingSpeed ?? 0}
                  />
                </div>
              </div>
              <div className="space-y-2">
                <Label htmlFor="address">Location label</Label>
                <Input
                  id="address"
                  name="address"
                  defaultValue={editing.trackingAddress ?? ''}
                  placeholder="Chicago yard, I-80 near Joliet…"
                />
              </div>
              <DialogFooter>
                <Button type="button" variant="outline" onClick={() => setEditing(null)}>
                  Cancel
                </Button>
                <Button type="submit" disabled={isPending}>
                  {isPending ? 'Saving…' : 'Save location'}
                </Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}
