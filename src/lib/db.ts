import { PrismaClient } from '@/generated/prisma/client'
import { getConnectionString } from '@netlify/database'
import { PrismaPg } from '@prisma/adapter-pg'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

function createPrismaClient() {
  let connectionString = process.env.DATABASE_URL ?? process.env.NETLIFY_DB_URL

  if (!connectionString) {
    try {
      connectionString = getConnectionString()
    } catch {
      // The explicit error below is more useful outside Netlify.
    }
  }

  if (!connectionString) {
    throw new Error('DATABASE_URL (or NETLIFY_DB_URL) must be configured before starting the app.')
  }

  const adapter = new PrismaPg({
    connectionString,
    max: 10,
    connectionTimeoutMillis: 5000,
    idleTimeoutMillis: 30000,
  })
  return new PrismaClient({
    adapter,
    log: process.env.NODE_ENV === 'development' ? ['warn', 'error'] : ['error'],
  })
}

export const db = globalForPrisma.prisma ?? createPrismaClient()

globalForPrisma.prisma = db
