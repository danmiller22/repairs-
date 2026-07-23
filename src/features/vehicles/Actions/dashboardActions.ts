'use server'

import { db } from '@/lib/db'
import { withAuth } from '@/lib/with-auth'
import { PermissionAction, PermissionSubject } from '@/lib/permissions'

export async function getDashboardStats() {
  return withAuth(
    async ({ organizationId }) => {
      const since = new Date()
      since.setDate(since.getDate() - 30)

      const [recentCosts, trucks, trailers, locatedNow] = await Promise.all([
        db.serviceRecord.findMany({
          where: { vehicle: { organizationId }, serviceDate: { gte: since } },
          select: { totalAmount: true, cost: true },
        }),
        db.vehicle.count({ where: { organizationId, isArchived: false, assetType: 'truck' } }),
        db.vehicle.count({ where: { organizationId, isArchived: false, assetType: 'trailer' } }),
        db.vehicle.count({
          where: {
            organizationId,
            isArchived: false,
            trackingLatitude: { not: null },
            trackingLongitude: { not: null },
          },
        }),
      ])

      return {
        spentLast30Days: recentCosts.reduce(
          (sum, record) => sum + (record.totalAmount > 0 ? record.totalAmount : record.cost),
          0
        ),
        trucks,
        trailers,
        locatedNow,
      }
    },
    {
      requiredPermissions: [
        { action: PermissionAction.READ, subject: PermissionSubject.DASHBOARD },
      ],
    }
  )
}

export async function getUpcomingReminders() {
  return withAuth(
    async ({ organizationId }) => {
      return db.reminder.findMany({
        where: {
          isCompleted: false,
          vehicle: { organizationId },
        },
        include: {
          vehicle: {
            select: {
              id: true,
              make: true,
              model: true,
              year: true,
              licensePlate: true,
            },
          },
        },
        orderBy: { dueDate: 'asc' },
        take: 10,
      })
    },
    {
      requiredPermissions: [
        { action: PermissionAction.READ, subject: PermissionSubject.DASHBOARD },
      ],
    }
  )
}
