'use client'

import Link from 'next/link'
import { Container, DollarSign, MapPin, Truck } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { useFormatCurrency } from '@/components/currency-settings-context'

type DashboardStats = {
  spentLast30Days: number
  trucks: number
  trailers: number
  locatedNow: number
}

export function DashboardClient({ stats }: { stats: DashboardStats }) {
  const formatCurrency = useFormatCurrency()
  const cards = [
    {
      label: 'Spent in the last 30 days',
      value: formatCurrency(stats.spentLast30Days),
      icon: DollarSign,
      href: '/billing',
    },
    { label: 'Trucks', value: stats.trucks, icon: Truck, href: '/vehicles?type=truck' },
    {
      label: 'Trailers',
      value: stats.trailers,
      icon: Container,
      href: '/vehicles?type=trailer',
    },
    { label: 'Located now', value: stats.locatedNow, icon: MapPin, href: '/tracking' },
  ]

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Fleet overview</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          The essential operating numbers, without the noise.
        </p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {cards.map(({ label, value, icon: Icon, href }) => (
          <Link key={label} href={href}>
            <Card className="h-full border-0 py-5 shadow-sm transition-colors hover:bg-muted/40">
              <CardContent className="flex items-center justify-between gap-4 px-5">
                <div>
                  <p className="text-sm text-muted-foreground">{label}</p>
                  <p className="mt-2 text-3xl font-semibold tracking-tight">{value}</p>
                </div>
                <div className="rounded-xl bg-primary/10 p-3 text-primary">
                  <Icon className="h-6 w-6" />
                </div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  )
}
