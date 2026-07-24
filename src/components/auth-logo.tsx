'use client'

import Image from 'next/image'

export function AuthLogo({ alt }: { alt: string }) {
  return (
    <Image
      src="/us-team-logo.png"
      alt={alt}
      width={48}
      height={44}
      className="h-11 w-auto"
      priority
    />
  )
}
