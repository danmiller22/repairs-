import Image from 'next/image'
import { Compass, Lightbulb, ShieldCheck, Users } from 'lucide-react'
import { PageHeader } from '@/components/page-header'
import { Card, CardContent } from '@/components/ui/card'

export default function AboutPage() {
  const principles = [
    {
      icon: Lightbulb,
      title: 'Bring clarity',
      text: 'Good operations begin when information is visible, honest and easy to act on.',
    },
    {
      icon: ShieldCheck,
      title: 'Own the responsibility',
      text: 'Every unit, repair and dollar deserves care because people depend on the work behind it.',
    },
    {
      icon: Users,
      title: 'Build for the team',
      text: 'Tools should remove friction, preserve knowledge and help every manager make a better call.',
    },
  ]

  return (
    <>
      <PageHeader />
      <div className="flex flex-1 flex-col gap-6 p-4 pt-0">
        <section className="relative overflow-hidden rounded-2xl border bg-card p-8 shadow-sm sm:p-12">
          <div className="absolute -right-20 -top-24 h-64 w-64 rounded-full bg-primary/10 blur-3xl" />
          <div className="relative max-w-3xl">
            <Image
              src="/us-team-logo.png"
              alt="US Team Fleet"
              width={64}
              height={64}
              className="mb-6 rounded-xl"
            />
            <p className="text-sm font-semibold uppercase tracking-[0.24em] text-primary">
              US Team Fleet
            </p>
            <h1 className="mt-3 text-3xl font-semibold tracking-tight sm:text-5xl">
              It&apos;s our duty to bring people to the light.
            </h1>
            <p className="mt-5 max-w-2xl text-base leading-7 text-muted-foreground">
              This system was created by employee Dan Miller to give the team one clear place for
              trucks, trailers, repairs and the money that keeps the fleet moving.
            </p>
          </div>
        </section>

        <div className="grid gap-4 md:grid-cols-3">
          {principles.map(({ icon: Icon, title, text }) => (
            <Card key={title} className="border-0 shadow-sm">
              <CardContent className="p-6">
                <div className="mb-4 inline-flex rounded-xl bg-primary/10 p-3 text-primary">
                  <Icon className="h-5 w-5" />
                </div>
                <h2 className="font-semibold">{title}</h2>
                <p className="mt-2 text-sm leading-6 text-muted-foreground">{text}</p>
              </CardContent>
            </Card>
          ))}
        </div>

        <div className="flex items-center gap-3 rounded-xl border bg-muted/30 p-5 text-sm text-muted-foreground">
          <Compass className="h-5 w-5 shrink-0 text-primary" />
          <p>
            The direction is simple: fewer distractions, better information and responsible action.
          </p>
        </div>
      </div>
    </>
  )
}
