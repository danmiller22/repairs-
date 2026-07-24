'use client'

import { useEffect, useMemo, useRef, useState, useTransition } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import {
  CircleAlert,
  Container,
  ExternalLink,
  Link2,
  Loader2,
  MapPin,
  Pencil,
  PlugZap,
  Plus,
  Radio,
  RefreshCw,
  Search,
  ShieldCheck,
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
import {
  saveTrackingProviderConnection,
  syncTrackingProvider,
  updateManualTrackingLocation,
} from '../Actions/trackingActions'
import type { TrackingAsset, TrackingConnection } from '../types'
import { TrackingMap } from './tracking-map-dynamic'

type ConfigurableProvider = 'samsara' | 'xtralease' | 'premier'

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

function formatDwell(value: string | null, status: string | null) {
  if (status === 'moving') return 'In motion'
  if (!value) return '—'
  const minutes = Math.max(0, Math.floor((Date.now() - new Date(value).getTime()) / 60_000))
  const days = Math.floor(minutes / 1440)
  const hours = Math.floor((minutes % 1440) / 60)
  const mins = minutes % 60
  if (days) return `${days}d ${hours}h`
  if (hours) return `${hours}h ${mins}m`
  return `${mins}m`
}

function providerName(provider: ConfigurableProvider) {
  if (provider === 'samsara') return 'Samsara'
  if (provider === 'xtralease') return 'XTRA Lease'
  return 'Premier Trailer'
}

export function TrackingClient({
  assets,
  connections = [],
}: {
  assets: TrackingAsset[]
  connections?: TrackingConnection[]
}) {
  const router = useRouter()
  const [filter, setFilter] = useState<'all' | 'truck' | 'trailer'>('all')
  const [search, setSearch] = useState('')
  const [editing, setEditing] = useState<TrackingAsset | null>(null)
  const [configuring, setConfiguring] = useState<ConfigurableProvider | null>(null)
  const [syncing, setSyncing] = useState<ConfigurableProvider | null>(null)
  const autoSyncAttempted = useRef(false)
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
        cargoStatus: formData.get('cargoStatus') || undefined,
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

  const syncProvider = (provider: ConfigurableProvider) => {
    setSyncing(provider)
    startTransition(async () => {
      const result = await syncTrackingProvider(provider)
      if (result.success && result.data) {
        const name = providerName(provider)
        toast.success(
          result.data.skipped
            ? `${name} is already current. XTRA sync is limited to once every 30 minutes.`
            : `${name} synced ${result.data.assetCount} units`
        )
        router.refresh()
      } else {
        toast.error(result.error || 'Tracking sync failed')
        router.refresh()
      }
      setSyncing(null)
    })
  }

  const saveConnection = (formData: FormData) => {
    if (!configuring) return
    const provider = configuring
    startTransition(async () => {
      const result =
        provider === 'samsara'
          ? await saveTrackingProviderConnection({
              provider,
              apiKey: formData.get('apiKey'),
            })
          : provider === 'xtralease'
            ? await saveTrackingProviderConnection({
                provider,
                username: formData.get('username'),
                password: formData.get('password'),
                serviceUrl: formData.get('serviceUrl'),
                apiVersion: formData.get('apiVersion'),
              })
            : await saveTrackingProviderConnection({
                provider,
                username: formData.get('username'),
                password: formData.get('password'),
              })

      if (result.success) {
        toast.success(`${providerName(provider)} connection saved`)
        setConfiguring(null)
        router.refresh()
      } else {
        toast.error(result.error || 'Could not save connection')
      }
    })
  }

  useEffect(() => {
    if (autoSyncAttempted.current) return
    const staleConnection = connections.find((connection) => {
      if (!connection.available || !connection.configured || connection.error) return false
      if (!connection.lastSyncedAt) return true
      return Date.now() - new Date(connection.lastSyncedAt).getTime() >= 30 * 60 * 1000
    })
    if (!staleConnection) return

    autoSyncAttempted.current = true
    const timeout = window.setTimeout(
      () => syncProvider(staleConnection.id as ConfigurableProvider),
      400
    )
    return () => window.clearTimeout(timeout)
  }, [connections])

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <h1 className="text-xl font-semibold tracking-tight sm:text-2xl">Fleet Tracking</h1>
            <Badge className="border-primary/25 bg-primary/10 text-primary" variant="outline">
              Integration ready
            </Badge>
          </div>
          <p className="mt-1 text-sm text-muted-foreground">
            Trucks and trailers in one live operational view.
          </p>
        </div>
        <Button asChild className="w-full sm:w-auto">
          <Link href="/vehicles?create=true">
            <Plus className="mr-1.5 h-4 w-4" />
            Add Unit
          </Link>
        </Button>
      </div>

      <div className="grid grid-cols-2 gap-2 sm:gap-3 lg:grid-cols-4">
        {[
          { label: 'All units', value: assets.length, icon: Radio },
          { label: 'Trucks', value: trucks, icon: Truck },
          { label: 'Trailers', value: trailers, icon: Container },
          { label: 'Located now', value: located, icon: MapPin },
        ].map(({ label, value, icon: Icon }) => (
          <Card key={label} className="border-0 py-3 shadow-sm sm:py-4">
            <CardContent className="flex items-center justify-between px-3 sm:px-4">
              <div>
                <p className="text-xs text-muted-foreground">{label}</p>
                <p className="mt-1 text-xl font-semibold sm:text-2xl">{value}</p>
              </div>
              <div className="rounded-lg bg-primary/10 p-2 text-primary sm:p-2.5">
                <Icon className="h-4 w-4 sm:h-5 sm:w-5" />
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-4 xl:grid-cols-[minmax(0,2fr)_minmax(280px,1fr)]">
        <Card className="overflow-hidden border-0 py-0 shadow-sm">
          <div className="h-[300px] sm:h-[380px] lg:h-[430px]">
            <TrackingMap assets={filteredAssets} />
          </div>
        </Card>

        <Card className="border-0 shadow-sm">
          <CardHeader className="gap-3">
            <div className="flex flex-col items-start gap-3 min-[420px]:flex-row min-[420px]:items-center min-[420px]:justify-between">
              <CardTitle className="flex items-center gap-2 text-base">
                <Link2 className="h-4 w-4 text-primary" />
                Tracking connections
              </CardTitle>
              <Button
                variant="outline"
                size="sm"
                className="w-full min-[420px]:w-auto"
                onClick={() => setConfiguring('samsara')}
              >
                <PlugZap className="mr-1.5 h-3.5 w-3.5" />
                Add provider
              </Button>
            </div>
            <p className="text-xs text-muted-foreground">
              Provider feeds will merge into the same truck and trailer list.
            </p>
          </CardHeader>
          <CardContent className="space-y-3">
            {connections.map((provider) => (
              <div key={provider.id} className="space-y-2 rounded-lg border p-3">
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <p className="text-sm font-medium">{provider.name}</p>
                    <p className="text-xs text-muted-foreground">{provider.scope}</p>
                  </div>
                  <Badge
                    variant="outline"
                    className={cn(
                      provider.error
                        ? 'border-amber-500/30 bg-amber-500/10 text-amber-500'
                        : provider.configured
                          ? 'border-emerald-500/30 bg-emerald-500/10 text-emerald-500'
                          : 'text-muted-foreground'
                    )}
                  >
                    {provider.error
                      ? 'Needs attention'
                      : provider.configured
                        ? 'Connected'
                        : provider.available
                          ? 'Not configured'
                          : 'Not configured'}
                  </Badge>
                </div>
                {provider.error ? (
                  <p className="flex gap-1.5 text-xs text-amber-500">
                    <CircleAlert className="mt-0.5 h-3.5 w-3.5 shrink-0" />
                    {provider.error}
                  </p>
                ) : provider.lastSyncedAt ? (
                  <p className="text-xs text-muted-foreground">
                    {provider.assetCount} units · synced {formatLastSeen(provider.lastSyncedAt)}
                  </p>
                ) : null}
                {provider.available && (
                  <div className="flex flex-col gap-2 min-[420px]:flex-row">
                    <Button
                      variant="outline"
                      size="sm"
                      className="h-7 flex-1 text-xs"
                      onClick={() => setConfiguring(provider.id as ConfigurableProvider)}
                    >
                      {provider.configured ? 'Replace credentials' : 'Connect'}
                    </Button>
                    {provider.configured && (
                      <Button
                        size="sm"
                        className="h-7 flex-1 text-xs"
                        disabled={syncing === provider.id}
                        onClick={() => syncProvider(provider.id as ConfigurableProvider)}
                      >
                        {syncing === provider.id ? (
                          <Loader2 className="mr-1.5 h-3.5 w-3.5 animate-spin" />
                        ) : (
                          <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
                        )}
                        Sync now
                      </Button>
                    )}
                  </div>
                )}
              </div>
            ))}
            <p className="text-xs text-muted-foreground">
              Connected providers refresh automatically when Tracking opens and data is over 30
              minutes old.
            </p>
          </CardContent>
        </Card>
      </div>

      <Card className="border-0 shadow-sm">
        <CardHeader className="gap-3 px-3 sm:flex-row sm:items-center sm:justify-between sm:px-6">
          <div>
            <CardTitle className="text-base">All tracked units</CardTitle>
            <p className="text-xs text-muted-foreground">One list for trucks and trailers</p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row">
            <div className="grid grid-cols-3 rounded-lg border p-1">
              {(['all', 'truck', 'trailer'] as const).map((value) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => setFilter(value)}
                  className={cn(
                    'min-h-8 rounded-md px-3 py-1 text-xs font-medium capitalize transition-colors',
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
        <CardContent className="px-3 pb-3 sm:px-6 sm:pb-6">
          <div className="space-y-3 md:hidden">
            {filteredAssets.length === 0 ? (
              <div className="rounded-lg border px-4 py-12 text-center text-sm text-muted-foreground">
                {assets.length === 0
                  ? 'No units yet. Add a truck or trailer in Fleet and it will appear here automatically.'
                  : 'No units match this filter.'}
              </div>
            ) : (
              filteredAssets.map((asset) => {
                const status = asset.trackingStatus || 'offline'
                const hasLocation =
                  asset.trackingLatitude !== null && asset.trackingLongitude !== null
                return (
                  <div key={asset.id} className="rounded-xl border bg-card p-3 shadow-sm">
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0">
                        <Link
                          href={`/vehicles/${asset.id}`}
                          className="block truncate font-semibold hover:text-primary"
                        >
                          {asset.licensePlate || `${asset.year} ${asset.make}`}
                        </Link>
                        <p className="truncate text-xs text-muted-foreground">
                          {asset.year} {asset.make} {asset.model}
                        </p>
                      </div>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-10 w-10 shrink-0"
                        aria-label="Update location"
                        onClick={() => setEditing(asset)}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                    </div>

                    <div className="mt-3 flex flex-wrap items-center gap-2">
                      <Badge variant="outline" className={cn('capitalize', statusStyles[status])}>
                        {status}
                      </Badge>
                      {asset.assetType === 'trailer' && (
                        <Badge
                          variant="outline"
                          className={cn(
                            'capitalize',
                            asset.trackingCargoStatus === 'loaded'
                              ? 'border-emerald-500/25 bg-emerald-500/10 text-emerald-500'
                              : asset.trackingCargoStatus === 'empty'
                                ? 'border-blue-500/25 bg-blue-500/10 text-blue-500'
                                : 'text-muted-foreground'
                          )}
                        >
                          {asset.trackingCargoStatus || 'unknown'}
                        </Badge>
                      )}
                      <span className="text-xs capitalize text-muted-foreground">
                        {asset.trackingProvider || 'Not connected'}
                      </span>
                    </div>

                    <div className="mt-3 grid grid-cols-2 gap-3 border-t pt-3 text-xs">
                      <div>
                        <p className="text-muted-foreground">At location</p>
                        <p className="mt-0.5 font-medium">
                          {asset.assetType === 'trailer'
                            ? formatDwell(asset.trackingStoppedSince, asset.trackingStatus)
                            : '—'}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="text-muted-foreground">Updated</p>
                        <p className="mt-0.5 font-medium">
                          {formatLastSeen(asset.trackingLastSeenAt)}
                        </p>
                      </div>
                    </div>

                    <div className="mt-3 min-w-0 text-sm">
                      {hasLocation ? (
                        <a
                          href={`https://www.openstreetmap.org/?mlat=${asset.trackingLatitude}&mlon=${asset.trackingLongitude}#map=15/${asset.trackingLatitude}/${asset.trackingLongitude}`}
                          target="_blank"
                          rel="noreferrer"
                          className="flex min-w-0 items-center gap-1 text-muted-foreground hover:text-primary"
                        >
                          <MapPin className="h-3.5 w-3.5 shrink-0" />
                          <span className="truncate">
                            {asset.trackingAddress ||
                              `${asset.trackingLatitude?.toFixed(4)}, ${asset.trackingLongitude?.toFixed(4)}`}
                          </span>
                          <ExternalLink className="h-3 w-3 shrink-0" />
                        </a>
                      ) : (
                        <span className="text-muted-foreground">No location</span>
                      )}
                    </div>
                  </div>
                )
              })
            )}
          </div>

          <div className="hidden overflow-x-auto rounded-lg border md:block">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Unit</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Motion</TableHead>
                  <TableHead>At location</TableHead>
                  <TableHead>Load</TableHead>
                  <TableHead>Provider</TableHead>
                  <TableHead>Last location</TableHead>
                  <TableHead>Updated</TableHead>
                  <TableHead className="w-12" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredAssets.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={9} className="h-32 text-center text-muted-foreground">
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
                        <TableCell className="whitespace-nowrap text-sm">
                          {asset.assetType === 'trailer'
                            ? formatDwell(asset.trackingStoppedSince, asset.trackingStatus)
                            : '—'}
                        </TableCell>
                        <TableCell>
                          {asset.assetType === 'trailer' ? (
                            <Badge
                              variant="outline"
                              className={cn(
                                'capitalize',
                                asset.trackingCargoStatus === 'loaded'
                                  ? 'border-emerald-500/25 bg-emerald-500/10 text-emerald-500'
                                  : asset.trackingCargoStatus === 'empty'
                                    ? 'border-blue-500/25 bg-blue-500/10 text-blue-500'
                                    : 'text-muted-foreground'
                              )}
                            >
                              {asset.trackingCargoStatus || 'unknown'}
                            </Badge>
                          ) : (
                            '—'
                          )}
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
              {editing.assetType === 'trailer' && (
                <div className="space-y-2">
                  <Label htmlFor="cargoStatus">Load status</Label>
                  <Select
                    name="cargoStatus"
                    defaultValue={editing.trackingCargoStatus || 'unknown'}
                  >
                    <SelectTrigger id="cargoStatus">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="empty">Empty</SelectItem>
                      <SelectItem value="loaded">Loaded</SelectItem>
                      <SelectItem value="unknown">Unknown</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              )}
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

      <Dialog open={!!configuring} onOpenChange={(open) => !open && setConfiguring(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Connect tracking provider</DialogTitle>
            <DialogDescription>
              Credentials are encrypted on the server and are never sent back to the browser.
            </DialogDescription>
          </DialogHeader>
          {configuring && (
            <form action={saveConnection} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="provider">Provider</Label>
                <Select
                  value={configuring}
                  onValueChange={(value) => setConfiguring(value as ConfigurableProvider)}
                >
                  <SelectTrigger id="provider">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="samsara">Samsara</SelectItem>
                    <SelectItem value="xtralease">XTRA Lease / SkyBitz</SelectItem>
                    <SelectItem value="premier">Premier Trailer / FleetLocate</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {configuring === 'samsara' ? (
                <div className="space-y-2">
                  <Label htmlFor="apiKey">Samsara API token</Label>
                  <Input
                    id="apiKey"
                    name="apiKey"
                    type="password"
                    autoComplete="new-password"
                    placeholder="samsara_api_…"
                    required
                  />
                  <p className="text-xs text-muted-foreground">
                    The token needs Read Vehicles and Read Vehicle Statistics permissions.
                  </p>
                </div>
              ) : configuring === 'xtralease' ? (
                <>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-2">
                      <Label htmlFor="username">SkyBitz username</Label>
                      <Input id="username" name="username" autoComplete="off" required />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="password">SkyBitz password</Label>
                      <Input
                        id="password"
                        name="password"
                        type="password"
                        autoComplete="new-password"
                        required
                      />
                    </div>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="serviceUrl">Service URL</Label>
                    <Input
                      id="serviceUrl"
                      name="serviceUrl"
                      type="url"
                      defaultValue="https://xml.skybitz.com/"
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="apiVersion">API version</Label>
                    <Input id="apiVersion" name="apiVersion" defaultValue="2.76" required />
                  </div>
                </>
              ) : (
                <>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-2">
                      <Label htmlFor="username">FleetLocate username</Label>
                      <Input
                        id="username"
                        name="username"
                        type="email"
                        autoComplete="off"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="password">FleetLocate password</Label>
                      <Input
                        id="password"
                        name="password"
                        type="password"
                        autoComplete="new-password"
                        required
                      />
                    </div>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    Premier trailers sync through Spireon FleetLocate, including GPS, dwell time and
                    empty/loaded status.
                  </p>
                </>
              )}

              <div className="flex items-start gap-2 rounded-lg bg-muted/60 p-3 text-xs text-muted-foreground">
                <ShieldCheck className="mt-0.5 h-4 w-4 shrink-0 text-primary" />
                Saving a new connection replaces the current credentials for this provider.
              </div>
              <DialogFooter>
                <Button type="button" variant="outline" onClick={() => setConfiguring(null)}>
                  Cancel
                </Button>
                <Button type="submit" disabled={isPending}>
                  {isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                  Save connection
                </Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}
