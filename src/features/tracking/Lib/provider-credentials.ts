import 'server-only'

import { createCipheriv, createDecipheriv, createHash, randomBytes } from 'node:crypto'
import { db } from '@/lib/db'

export type TrackingProviderId = 'samsara' | 'xtralease'

export type SamsaraCredentials = {
  apiKey: string
}

export type XtraLeaseCredentials = {
  username: string
  password: string
  serviceUrl: string
  apiVersion: string
}

export type TrackingCredentials = SamsaraCredentials | XtraLeaseCredentials

export type TrackingSyncMetadata = {
  lastSyncedAt: string | null
  assetCount: number
  error: string | null
}

const connectionKey = (provider: TrackingProviderId) => `tracking_connection_${provider}`
const syncKey = (provider: TrackingProviderId) => `tracking_sync_${provider}`

function encryptionKey() {
  const secret = process.env.TRACKING_ENCRYPTION_KEY || process.env.BETTER_AUTH_SECRET
  if (!secret || secret.length < 20) {
    throw new Error('Tracking credential encryption is not configured')
  }
  return createHash('sha256').update(secret).digest()
}

function encrypt(value: TrackingCredentials) {
  const iv = randomBytes(12)
  const cipher = createCipheriv('aes-256-gcm', encryptionKey(), iv)
  const encrypted = Buffer.concat([cipher.update(JSON.stringify(value), 'utf8'), cipher.final()])
  const tag = cipher.getAuthTag()
  return [
    'v1',
    iv.toString('base64url'),
    tag.toString('base64url'),
    encrypted.toString('base64url'),
  ].join('.')
}

function decrypt(value: string): TrackingCredentials {
  const [version, ivValue, tagValue, encryptedValue] = value.split('.')
  if (version !== 'v1' || !ivValue || !tagValue || !encryptedValue) {
    throw new Error('Stored tracking credentials are invalid')
  }

  const decipher = createDecipheriv(
    'aes-256-gcm',
    encryptionKey(),
    Buffer.from(ivValue, 'base64url')
  )
  decipher.setAuthTag(Buffer.from(tagValue, 'base64url'))
  const decrypted = Buffer.concat([
    decipher.update(Buffer.from(encryptedValue, 'base64url')),
    decipher.final(),
  ])
  return JSON.parse(decrypted.toString('utf8')) as TrackingCredentials
}

function credentialsFromEnvironment(provider: TrackingProviderId): TrackingCredentials | null {
  if (provider === 'samsara') {
    return process.env.SAMSARA_API_KEY ? { apiKey: process.env.SAMSARA_API_KEY } : null
  }

  if (!process.env.XTRA_SKYBITZ_USERNAME || !process.env.XTRA_SKYBITZ_PASSWORD) return null
  return {
    username: process.env.XTRA_SKYBITZ_USERNAME,
    password: process.env.XTRA_SKYBITZ_PASSWORD,
    serviceUrl: process.env.XTRA_SKYBITZ_SERVICE_URL || 'https://xml.skybitz.com/',
    apiVersion: process.env.XTRA_SKYBITZ_API_VERSION || '2.76',
  }
}

export async function getTrackingCredentials(organizationId: string, provider: TrackingProviderId) {
  const stored = await db.appSetting.findUnique({
    where: {
      organizationId_key: {
        organizationId,
        key: connectionKey(provider),
      },
    },
    select: { value: true },
  })

  if (stored?.value) {
    return { credentials: decrypt(stored.value), source: 'secure-settings' as const }
  }

  const environmentCredentials = credentialsFromEnvironment(provider)
  return environmentCredentials
    ? { credentials: environmentCredentials, source: 'environment' as const }
    : { credentials: null, source: null }
}

export async function saveTrackingCredentials(
  organizationId: string,
  userId: string,
  provider: TrackingProviderId,
  credentials: TrackingCredentials
) {
  await db.appSetting.upsert({
    where: {
      organizationId_key: {
        organizationId,
        key: connectionKey(provider),
      },
    },
    update: { value: encrypt(credentials) },
    create: {
      organizationId,
      userId,
      key: connectionKey(provider),
      value: encrypt(credentials),
    },
  })
}

export async function getTrackingSyncMetadata(
  organizationId: string,
  provider: TrackingProviderId
): Promise<TrackingSyncMetadata> {
  const stored = await db.appSetting.findUnique({
    where: {
      organizationId_key: {
        organizationId,
        key: syncKey(provider),
      },
    },
    select: { value: true },
  })

  if (!stored?.value) return { lastSyncedAt: null, assetCount: 0, error: null }
  try {
    const parsed = JSON.parse(stored.value) as Partial<TrackingSyncMetadata>
    return {
      lastSyncedAt: parsed.lastSyncedAt ?? null,
      assetCount: parsed.assetCount ?? 0,
      error: parsed.error ?? null,
    }
  } catch {
    return { lastSyncedAt: null, assetCount: 0, error: null }
  }
}

export async function saveTrackingSyncMetadata(
  organizationId: string,
  userId: string,
  provider: TrackingProviderId,
  metadata: TrackingSyncMetadata
) {
  await db.appSetting.upsert({
    where: {
      organizationId_key: {
        organizationId,
        key: syncKey(provider),
      },
    },
    update: { value: JSON.stringify(metadata) },
    create: {
      organizationId,
      userId,
      key: syncKey(provider),
      value: JSON.stringify(metadata),
    },
  })
}
