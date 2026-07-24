'use server'

import { revalidatePath } from 'next/cache'
import { z } from 'zod'
import { db } from '@/lib/db'
import { withAuth } from '@/lib/with-auth'
import { PermissionAction, PermissionSubject } from '@/lib/permissions'
import {
  getTrackingCredentials,
  getTrackingSyncMetadata,
  saveTrackingCredentials,
  saveTrackingSyncMetadata,
  type TrackingProviderId,
} from '../Lib/provider-credentials'
import { syncProviderUnits } from '../Lib/provider-sync'
import type { TrackingConnection } from '../types'

const manualLocationSchema = z.object({
  vehicleId: z.string().min(1),
  latitude: z.coerce.number().min(-90).max(90),
  longitude: z.coerce.number().min(-180).max(180),
  speed: z.coerce.number().min(0).max(200).optional(),
  status: z.enum(['moving', 'stopped', 'idle', 'maintenance', 'offline']),
  address: z.string().trim().max(250).optional(),
  cargoStatus: z.enum(['empty', 'loaded', 'unknown']).optional(),
})

const providerSchema = z.enum(['samsara', 'xtralease', 'premier'])

const saveConnectionSchema = z.discriminatedUnion('provider', [
  z.object({
    provider: z.literal('samsara'),
    apiKey: z.string().trim().min(20, 'Enter a valid Samsara API token'),
  }),
  z.object({
    provider: z.literal('xtralease'),
    username: z.string().trim().min(3),
    password: z.string().min(8),
    serviceUrl: z
      .string()
      .url()
      .startsWith('https://')
      .refine((value) => new URL(value).hostname === 'xml.skybitz.com', {
        message: 'XTRA Lease service URL must use xml.skybitz.com',
      }),
    apiVersion: z
      .string()
      .trim()
      .regex(/^\d+\.\d+$/),
  }),
  z.object({
    provider: z.literal('premier'),
    username: z.string().trim().email(),
    password: z.string().min(8),
  }),
])

export async function getTrackingAssets() {
  return withAuth(
    async ({ organizationId }) => {
      return db.vehicle.findMany({
        where: { organizationId, isArchived: false },
        select: {
          id: true,
          assetType: true,
          make: true,
          model: true,
          year: true,
          vin: true,
          licensePlate: true,
          trackingProvider: true,
          trackingExternalId: true,
          trackingLatitude: true,
          trackingLongitude: true,
          trackingSpeed: true,
          trackingHeading: true,
          trackingStatus: true,
          trackingAddress: true,
          trackingLastSeenAt: true,
          trackingStoppedSince: true,
          trackingCargoStatus: true,
        },
        orderBy: [{ assetType: 'asc' }, { licensePlate: 'asc' }, { updatedAt: 'desc' }],
      })
    },
    {
      requiredPermissions: [{ action: PermissionAction.READ, subject: PermissionSubject.VEHICLES }],
    }
  )
}

export async function updateManualTrackingLocation(input: unknown) {
  return withAuth(
    async ({ organizationId }) => {
      const data = manualLocationSchema.parse(input)
      const result = await db.vehicle.updateMany({
        where: { id: data.vehicleId, organizationId, isArchived: false },
        data: {
          trackingProvider: 'manual',
          trackingLatitude: data.latitude,
          trackingLongitude: data.longitude,
          trackingSpeed: data.speed ?? 0,
          trackingStatus: data.status,
          trackingAddress: data.address || null,
          trackingLastSeenAt: new Date(),
          trackingStoppedSince:
            data.status === 'stopped' || data.status === 'idle' ? new Date() : null,
          trackingCargoStatus: data.cargoStatus || 'unknown',
        },
      })

      if (result.count === 0) throw new Error('Unit not found')
      revalidatePath('/tracking')
      return { id: data.vehicleId }
    },
    {
      requiredPermissions: [
        { action: PermissionAction.UPDATE, subject: PermissionSubject.VEHICLES },
      ],
      audit: ({ result }) => ({
        action: 'tracking.manual_update',
        entity: 'Vehicle',
        entityId: result.id,
        message: 'Updated unit location manually',
        metadata: { vehicleId: result.id },
      }),
    }
  )
}

export async function getTrackingConnections() {
  return withAuth(
    async ({ organizationId }) => {
      const providerIds: TrackingProviderId[] = ['samsara', 'xtralease', 'premier']
      const configured = await Promise.all(
        providerIds.map(async (provider) => {
          const metadata = await getTrackingSyncMetadata(organizationId, provider)
          try {
            const connection = await getTrackingCredentials(organizationId, provider)
            return { provider, connection, metadata }
          } catch (error) {
            return {
              provider,
              connection: { credentials: null, source: null },
              metadata: {
                ...metadata,
                error:
                  error instanceof Error
                    ? error.message
                    : 'Stored tracking credentials are unavailable',
              },
            }
          }
        })
      )

      const definitions = {
        samsara: { name: 'Samsara', scope: 'Trucks' },
        xtralease: { name: 'XTRA Lease', scope: 'Trailers via SkyBitz' },
        premier: { name: 'Premier Trailer', scope: 'Trailers via FleetLocate' },
      } as const

      const connections: TrackingConnection[] = configured.map(
        ({ provider, connection, metadata }) => ({
          id: provider,
          ...definitions[provider],
          configured: !!connection.credentials,
          available: true,
          source: connection.source,
          ...metadata,
        })
      )

      return connections
    },
    {
      requiredPermissions: [{ action: PermissionAction.READ, subject: PermissionSubject.VEHICLES }],
    }
  )
}

export async function saveTrackingProviderConnection(input: unknown) {
  return withAuth(
    async ({ organizationId, userId }) => {
      const data = saveConnectionSchema.parse(input)
      const credentials =
        data.provider === 'samsara'
          ? { apiKey: data.apiKey }
          : data.provider === 'xtralease'
            ? {
                username: data.username,
                password: data.password,
                serviceUrl: data.serviceUrl,
                apiVersion: data.apiVersion,
              }
            : {
                username: data.username,
                password: data.password,
              }

      await saveTrackingCredentials(organizationId, userId, data.provider, credentials)
      await saveTrackingSyncMetadata(organizationId, userId, data.provider, {
        lastSyncedAt: null,
        assetCount: 0,
        error: null,
      })
      revalidatePath('/tracking')
      return { provider: data.provider }
    },
    {
      requiredPermissions: [
        { action: PermissionAction.UPDATE, subject: PermissionSubject.VEHICLES },
      ],
      audit: ({ result }) => ({
        action: 'tracking.connection_saved',
        entity: 'TrackingProvider',
        entityId: result.provider,
        message: `Saved ${result.provider} tracking connection`,
      }),
    }
  )
}

export async function syncTrackingProvider(input: unknown) {
  return withAuth(
    async ({ organizationId, userId }) => {
      const provider = providerSchema.parse(input) as TrackingProviderId
      const connection = await getTrackingCredentials(organizationId, provider)
      if (!connection.credentials) throw new Error(`${provider} is not configured`)

      try {
        if (provider === 'xtralease') {
          const previous = await getTrackingSyncMetadata(organizationId, provider)
          if (
            previous.lastSyncedAt &&
            Date.now() - new Date(previous.lastSyncedAt).getTime() < 30 * 60 * 1000
          ) {
            return {
              provider,
              assetCount: previous.assetCount,
              lastSyncedAt: previous.lastSyncedAt,
              skipped: true,
            }
          }
        }

        const assetCount = await syncProviderUnits({
          provider,
          credentials: connection.credentials,
          organizationId,
          userId,
        })
        const lastSyncedAt = new Date().toISOString()
        await saveTrackingSyncMetadata(organizationId, userId, provider, {
          lastSyncedAt,
          assetCount,
          error: null,
        })
        revalidatePath('/tracking')
        revalidatePath('/vehicles')
        revalidatePath('/')
        return { provider, assetCount, lastSyncedAt, skipped: false }
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Tracking sync failed'
        await saveTrackingSyncMetadata(organizationId, userId, provider, {
          lastSyncedAt: null,
          assetCount: 0,
          error: message,
        })
        throw error
      }
    },
    {
      requiredPermissions: [
        { action: PermissionAction.UPDATE, subject: PermissionSubject.VEHICLES },
      ],
      audit: ({ result }) => ({
        action: 'tracking.provider_sync',
        entity: 'TrackingProvider',
        entityId: result.provider,
        message: `Synced ${result.assetCount} units from ${result.provider}`,
        metadata: { assetCount: result.assetCount },
      }),
    }
  )
}
