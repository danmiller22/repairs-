'use server'

import { revalidatePath } from 'next/cache'
import { z } from 'zod'
import { db } from '@/lib/db'
import { withAuth } from '@/lib/with-auth'
import { PermissionAction, PermissionSubject } from '@/lib/permissions'

const manualLocationSchema = z.object({
  vehicleId: z.string().min(1),
  latitude: z.coerce.number().min(-90).max(90),
  longitude: z.coerce.number().min(-180).max(180),
  speed: z.coerce.number().min(0).max(200).optional(),
  status: z.enum(['moving', 'stopped', 'idle', 'maintenance', 'offline']),
  address: z.string().trim().max(250).optional(),
})

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
