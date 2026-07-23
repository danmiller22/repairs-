'use client'

import { useCallback, useEffect, useRef, useState, useTransition } from 'react'
import Image from 'next/image'
import Link from 'next/link'
import { usePathname, useRouter, useSearchParams } from 'next/navigation'
import {
  Container,
  Gauge,
  Grid3X3,
  LayoutGrid,
  List,
  Loader2,
  MoreVertical,
  Pencil,
  Plus,
  Search,
  Trash2,
  Truck,
} from 'lucide-react'
import { useTranslations } from 'next-intl'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Input } from '@/components/ui/input'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Badge } from '@/components/ui/badge'
import { DataTablePagination } from '@/components/data-table-pagination'
import { useGlassModal } from '@/components/glass-modal'
import { useConfirm } from '@/components/confirm-dialog'
import { VehicleForm } from '@/features/vehicles/Components/VehicleForm'
import { deleteVehicle } from '@/features/vehicles/Actions/vehicleActions'

interface Vehicle {
  id: string
  assetType: string
  make: string
  model: string
  year: number
  vin: string | null
  licensePlate: string | null
  trackingExternalId: string | null
  color: string | null
  mileage: number
  fuelType: string | null
  transmission: string | null
  engineSize: string | null
  engineCode: string | null
  imageUrl: string | null
  customerId: string | null
}

interface CustomerOption {
  id: string
  name: string
  company: string | null
}

interface PaginatedData {
  vehicles: Vehicle[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

const VIEW_COOKIE = 'torqvoice-vehicles-view'

export function VehiclesClient({
  data,
  customers,
  search,
  assetType = 'all',
  initialView = 'table',
}: {
  data: PaginatedData
  customers: CustomerOption[]
  search: string
  assetType?: 'all' | 'truck' | 'trailer'
  initialView?: 'table' | 'grid' | 'grid6'
}) {
  const router = useRouter()
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const [isPending, startTransition] = useTransition()
  const t = useTranslations('vehicles.list')
  const tc = useTranslations('common.buttons')
  const [showForm, setShowForm] = useState(false)
  const [editVehicle, setEditVehicle] = useState<Vehicle | null>(null)
  const [view, setView] = useState<'table' | 'grid' | 'grid6'>(initialView)
  const modal = useGlassModal()
  const confirm = useConfirm()

  useEffect(() => {
    if (searchParams.get('create') !== 'true') return
    setShowForm(true)
    const params = new URLSearchParams(searchParams.toString())
    params.delete('create')
    window.history.replaceState(null, '', params.toString() ? `${pathname}?${params}` : pathname)
  }, [searchParams, pathname])

  const toggleView = (nextView: 'table' | 'grid' | 'grid6') => {
    setView(nextView)
    document.cookie = `${VIEW_COOKIE}=${nextView};path=/;max-age=${60 * 60 * 24 * 365}`
  }

  const navigate = useCallback(
    (params: Record<string, string | number | undefined>) => {
      const next = new URLSearchParams(searchParams.toString())
      for (const [key, value] of Object.entries(params)) {
        if (value === undefined || value === '') next.delete(key)
        else next.set(key, String(value))
      }
      if (!('page' in params) && ('search' in params || 'type' in params)) next.delete('page')
      startTransition(() => router.push(next.toString() ? `${pathname}?${next}` : pathname))
    },
    [router, pathname, searchParams]
  )

  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const handleSearchChange = useCallback(
    (value: string) => {
      if (debounceRef.current) clearTimeout(debounceRef.current)
      debounceRef.current = setTimeout(() => navigate({ search: value || undefined }), 300)
    },
    [navigate]
  )

  useEffect(
    () => () => {
      if (debounceRef.current) clearTimeout(debounceRef.current)
    },
    []
  )

  const handleDelete = async (vehicle: Vehicle) => {
    const unit =
      vehicle.trackingExternalId || vehicle.licensePlate || `${vehicle.year} ${vehicle.make}`
    const ok = await confirm({
      title: t('deleteTitle'),
      description: t('deleteDescription', { name: unit }),
      confirmLabel: tc('delete'),
      destructive: true,
    })
    if (!ok) return
    const result = await deleteVehicle(vehicle.id)
    if (result.success) router.refresh()
    else modal.open('error', 'Error', result.error || t('deleteError'))
  }

  const unitNumber = (vehicle: Vehicle) =>
    vehicle.trackingExternalId || vehicle.licensePlate || 'Not assigned'

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex min-w-0 flex-1 items-center gap-2">
          <div className="flex shrink-0 gap-1 rounded-lg border p-1">
            {[
              { value: 'all', label: 'All Units' },
              { value: 'truck', label: 'Trucks' },
              { value: 'trailer', label: 'Trailers' },
            ].map((item) => (
              <button
                key={item.value}
                type="button"
                onClick={() => navigate({ type: item.value === 'all' ? undefined : item.value })}
                className={`rounded-md px-3 py-1 text-xs font-medium transition-colors ${
                  assetType === item.value
                    ? 'bg-primary text-primary-foreground'
                    : 'text-muted-foreground hover:text-foreground'
                }`}
              >
                {item.label}
              </button>
            ))}
          </div>
          <div className="relative min-w-0 flex-1 sm:max-w-sm">
            <Search className="absolute left-2.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Search unit number, make, model or VIN…"
              defaultValue={search}
              onChange={(event) => handleSearchChange(event.target.value)}
              className="pl-9"
            />
          </div>
          {isPending && <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />}
        </div>
        <div className="flex shrink-0 items-center gap-2">
          <div className="flex items-center rounded-md border">
            <Button
              variant={view === 'table' ? 'secondary' : 'ghost'}
              size="icon"
              className="h-8 w-8 rounded-r-none"
              onClick={() => toggleView('table')}
              aria-label={t('viewTable')}
            >
              <List className="h-4 w-4" />
            </Button>
            <Button
              variant={view === 'grid' ? 'secondary' : 'ghost'}
              size="icon"
              className="h-8 w-8 rounded-none border-x"
              onClick={() => toggleView('grid')}
              aria-label={t('viewGrid')}
            >
              <LayoutGrid className="h-4 w-4" />
            </Button>
            <Button
              variant={view === 'grid6' ? 'secondary' : 'ghost'}
              size="icon"
              className="hidden h-8 w-8 rounded-l-none lg:inline-flex"
              onClick={() => toggleView('grid6')}
              aria-label={t('viewLargeGrid')}
            >
              <Grid3X3 className="h-4 w-4" />
            </Button>
          </div>
          <Button size="sm" onClick={() => setShowForm(true)}>
            <Plus className="mr-1 h-3.5 w-3.5" />
            Add Unit
          </Button>
        </div>
      </div>

      {data.vehicles.length === 0 ? (
        <div className="flex h-32 items-center justify-center rounded-lg border text-muted-foreground">
          {search ? 'No units match your search.' : 'No units in this category.'}
        </div>
      ) : view === 'table' ? (
        <div className="rounded-lg border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[160px]">Unit Number</TableHead>
                <TableHead>Equipment</TableHead>
                <TableHead className="w-[120px]">Category</TableHead>
                <TableHead className="w-[120px] text-right">Mileage</TableHead>
                <TableHead className="w-[50px]" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.vehicles.map((vehicle) => (
                <TableRow
                  key={vehicle.id}
                  className="cursor-pointer"
                  onClick={() => router.push(`/vehicles/${vehicle.id}`)}
                >
                  <TableCell className="font-mono font-semibold">{unitNumber(vehicle)}</TableCell>
                  <TableCell className="font-medium">
                    {vehicle.year} {vehicle.make} {vehicle.model}
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline" className="gap-1.5 capitalize">
                      {vehicle.assetType === 'trailer' ? (
                        <Container className="h-3.5 w-3.5" />
                      ) : (
                        <Truck className="h-3.5 w-3.5" />
                      )}
                      {vehicle.assetType === 'trailer' ? 'Trailer' : 'Truck'}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-right font-mono text-sm">
                    {new Intl.NumberFormat('en-US').format(vehicle.mileage)}
                  </TableCell>
                  <TableCell>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild onClick={(event) => event.stopPropagation()}>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8"
                          aria-label="Open menu"
                        >
                          <MoreVertical className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem
                          onClick={(event) => {
                            event.stopPropagation()
                            setEditVehicle(vehicle)
                            setShowForm(true)
                          }}
                        >
                          <Pencil className="mr-2 h-4 w-4" />
                          Edit
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          className="text-destructive"
                          onClick={(event) => {
                            event.stopPropagation()
                            handleDelete(vehicle)
                          }}
                        >
                          <Trash2 className="mr-2 h-4 w-4" />
                          Delete
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      ) : isPending ? (
        <div
          className={`grid gap-4 sm:grid-cols-2 lg:grid-cols-3 ${
            view === 'grid6' ? 'xl:grid-cols-4 2xl:grid-cols-6' : 'xl:grid-cols-4'
          }`}
        >
          {Array.from({ length: view === 'grid6' ? 12 : 6 }).map((_, index) => (
            <Card key={index} className="overflow-hidden border-0 py-0 shadow-sm">
              <Skeleton className="aspect-[16/10] rounded-none" />
            </Card>
          ))}
        </div>
      ) : (
        <div
          className={`grid gap-4 sm:grid-cols-2 lg:grid-cols-3 ${
            view === 'grid6' ? 'xl:grid-cols-4 2xl:grid-cols-6' : 'xl:grid-cols-4'
          }`}
        >
          {data.vehicles.map((vehicle) => (
            <Card
              key={vehicle.id}
              className="group overflow-hidden border-0 py-0 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-lg"
            >
              <Link href={`/vehicles/${vehicle.id}`}>
                <div className="relative aspect-[16/10] overflow-hidden bg-muted">
                  <Image
                    src={vehicle.imageUrl || '/truck_placeholder.svg'}
                    alt={`${vehicle.year} ${vehicle.make} ${vehicle.model}`}
                    fill
                    unoptimized
                    className="object-cover transition-transform duration-300 group-hover:scale-105"
                  />
                  <div className="absolute inset-x-0 bottom-0 h-2/3 bg-gradient-to-t from-black/75 to-transparent" />
                  <Badge className="absolute left-3 top-3 capitalize">
                    {vehicle.assetType === 'trailer' ? 'Trailer' : 'Truck'}
                  </Badge>
                  <div className="absolute inset-x-0 bottom-0 p-4 text-white">
                    <p className="font-mono text-lg font-bold">{unitNumber(vehicle)}</p>
                    <p className="text-sm text-white/80">
                      {vehicle.year} {vehicle.make} {vehicle.model}
                    </p>
                  </div>
                </div>
                <CardContent className="flex items-center justify-between px-4 py-2 text-sm">
                  <div className="flex items-center gap-1.5">
                    <Gauge className="h-3.5 w-3.5" />
                    {new Intl.NumberFormat('en-US').format(vehicle.mileage)} mi
                  </div>
                </CardContent>
              </Link>
            </Card>
          ))}
        </div>
      )}

      <DataTablePagination
        total={data.total}
        page={data.page}
        pageSize={data.pageSize}
        totalPages={data.totalPages}
        onNavigate={navigate}
      />

      <VehicleForm
        open={showForm}
        onOpenChange={(open) => {
          setShowForm(open)
          if (!open) setEditVehicle(null)
        }}
        vehicle={editVehicle ?? undefined}
        customers={customers}
      />
    </div>
  )
}
