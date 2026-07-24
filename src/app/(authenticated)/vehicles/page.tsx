import { cookies } from 'next/headers'
import { getTranslations } from 'next-intl/server'
import { getVehiclesPaginated } from '@/features/vehicles/Actions/vehicleActions'
import { getCustomersList } from '@/features/customers/Actions/customerActions'
import { VehiclesClient } from './vehicles-client'
import { PageHeader } from '@/components/page-header'

export default async function VehiclesPage({
  searchParams,
}: {
  searchParams: Promise<{
    page?: string
    pageSize?: string
    search?: string
    type?: string
  }>
}) {
  const params = await searchParams
  const assetType = params.type === 'truck' || params.type === 'trailer' ? params.type : 'all'
  const cookieStore = await cookies()
  const viewCookie = cookieStore.get('torqvoice-vehicles-view')?.value
  const initialView = viewCookie === 'grid' ? 'grid' : viewCookie === 'grid6' ? 'grid6' : 'table'
  const [result, customersResult] = await Promise.all([
    getVehiclesPaginated({
      page: params.page ? parseInt(params.page) : 1,
      pageSize: params.pageSize ? parseInt(params.pageSize) : 20,
      search: params.search,
      assetType: assetType === 'all' ? undefined : assetType,
    }),
    getCustomersList(),
  ])

  if (!result.success || !result.data) {
    return (
      <>
        <PageHeader />
        <div className="flex h-[50vh] items-center justify-center">
          <p className="text-muted-foreground">
            {result.error || (await getTranslations('vehicles.list'))('error')}
          </p>
        </div>
      </>
    )
  }

  return (
    <>
      <PageHeader />
      <div className="flex flex-1 flex-col gap-4 px-3 pb-4 sm:px-4">
        <VehiclesClient
          data={result.data}
          customers={customersResult.data ?? []}
          search={params.search || ''}
          assetType={assetType}
          initialView={initialView}
        />
      </div>
    </>
  )
}
