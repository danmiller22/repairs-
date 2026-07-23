import { getTranslations } from 'next-intl/server'
import { PageHeader } from '@/components/page-header'
import { getDashboardStats } from '@/features/vehicles/Actions/dashboardActions'
import { DashboardClient } from './dashboard-client'

export default async function DashboardPage() {
  const result = await getDashboardStats()

  if (!result.success || !result.data) {
    const t = await getTranslations('dashboard')
    return (
      <>
        <PageHeader />
        <div className="flex h-[50vh] items-center justify-center">
          <p className="text-muted-foreground">{result.error || t('error')}</p>
        </div>
      </>
    )
  }

  return (
    <>
      <PageHeader />
      <div className="flex flex-1 flex-col gap-4 p-4 pt-0">
        <DashboardClient stats={result.data} />
      </div>
    </>
  )
}
