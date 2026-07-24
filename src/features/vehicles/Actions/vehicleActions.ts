'use server'

import { db } from '@/lib/db'
import { withAuth } from '@/lib/with-auth'
import { PermissionAction, PermissionSubject } from '@/lib/permissions'
import { createVehicleSchema, updateVehicleSchema } from '../Schema/vehicleSchema'
import { revalidatePath } from 'next/cache'
import { unlink } from 'fs/promises'
import { resolveUploadPath } from '@/lib/resolve-upload-path'
import { normalizeVehicleCsv } from '../Lib/vehicleCsvImport'

export async function getVehicles() {
  return withAuth(
    async ({ organizationId }) => {
      return db.vehicle.findMany({
        where: { organizationId, isArchived: false },
        include: {
          customer: { select: { id: true, name: true, company: true } },
          _count: {
            select: { serviceRecords: true, notes: true },
          },
        },
        orderBy: { updatedAt: 'desc' },
      })
    },
    {
      requiredPermissions: [{ action: PermissionAction.READ, subject: PermissionSubject.VEHICLES }],
    }
  )
}

export async function getVehicle(vehicleId: string) {
  return withAuth(
    async ({ organizationId }) => {
      const vehicle = await db.vehicle.findFirst({
        where: { id: vehicleId, organizationId },
        include: {
          customer: { select: { id: true, name: true, company: true, email: true, phone: true } },
          serviceRecords: {
            orderBy: [{ startDateTime: { sort: 'desc', nulls: 'last' } }, { serviceDate: 'desc' }],
            take: 10,
            include: {
              _count: { select: { partItems: true, laborItems: true } },
            },
          },
          notes: { orderBy: [{ isPinned: 'desc' }, { updatedAt: 'desc' }] },
          reminders: {
            orderBy: [{ isCompleted: 'asc' }, { dueDate: 'asc' }],
            select: {
              id: true,
              title: true,
              description: true,
              dueDate: true,
              dueMileage: true,
              isCompleted: true,
              createdAt: true,
            },
          },
          aiMessages: {
            select: { type: true, content: true, updatedAt: true },
          },
          _count: {
            select: {
              serviceRecords: true,
              notes: true,
              reminders: { where: { isCompleted: false } },
              findings: { where: { status: 'open' } },
            },
          },
        },
      })

      if (!vehicle) throw new Error('Vehicle not found')
      return vehicle
    },
    {
      requiredPermissions: [{ action: PermissionAction.READ, subject: PermissionSubject.VEHICLES }],
    }
  )
}

export async function getVehiclesPaginated(params: {
  page?: number
  pageSize?: number
  search?: string
  archived?: boolean
  assetType?: 'truck' | 'trailer'
}) {
  return withAuth(
    async ({ organizationId }) => {
      const page = params.page || 1
      const pageSize = params.pageSize || 20
      const skip = (page - 1) * pageSize

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const where: any = {
        organizationId,
        isArchived: false,
        ...(params.assetType ? { assetType: params.assetType } : {}),
      }

      if (params.search) {
        const words = params.search.trim().split(/\s+/).filter(Boolean)
        const fieldMatch = (word: string) => {
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          const conditions: any[] = [
            { trackingExternalId: { contains: word, mode: 'insensitive' } },
            { make: { contains: word, mode: 'insensitive' } },
            { model: { contains: word, mode: 'insensitive' } },
            { licensePlate: { contains: word, mode: 'insensitive' } },
            { vin: { contains: word, mode: 'insensitive' } },
            { customer: { name: { contains: word, mode: 'insensitive' } } },
          ]
          if (!isNaN(Number(word))) {
            conditions.push({ year: Number(word) })
          }
          return conditions
        }
        if (words.length > 1) {
          where.AND = words.map((word: string) => ({ OR: fieldMatch(word) }))
        } else {
          where.OR = fieldMatch(words[0])
        }
      }

      const [vehicles, total, archivedCount] = await Promise.all([
        db.vehicle.findMany({
          where,
          include: {
            customer: { select: { id: true, name: true, company: true } },
            _count: { select: { serviceRecords: true } },
          },
          orderBy: { updatedAt: 'desc' },
          skip,
          take: pageSize,
        }),
        db.vehicle.count({ where }),
        db.vehicle.count({ where: { organizationId, isArchived: true } }),
      ])

      return {
        vehicles,
        total,
        page,
        pageSize,
        totalPages: Math.ceil(total / pageSize),
        archivedCount,
      }
    },
    {
      requiredPermissions: [{ action: PermissionAction.READ, subject: PermissionSubject.VEHICLES }],
    }
  )
}

export async function createVehicle(input: unknown) {
  return withAuth(
    async ({ userId, organizationId }) => {
      const data = createVehicleSchema.parse(input)
      const vehicle = await db.vehicle.create({
        data: {
          ...data,
          purchaseDate: data.purchaseDate ? new Date(data.purchaseDate) : null,
          customerId: data.customerId || null,
          userId,
          organizationId,
        },
      })
      revalidatePath('/')
      revalidatePath('/vehicles')
      revalidatePath('/tracking')
      return vehicle
    },
    {
      requiredPermissions: [
        { action: PermissionAction.CREATE, subject: PermissionSubject.VEHICLES },
      ],
      audit: ({ result }) => ({
        action: 'vehicle.create',
        entity: 'Vehicle',
        entityId: result.id,
        message: `Created vehicle ${result.year} ${result.make} ${result.model}`,
        metadata: { vehicleId: result.id },
      }),
    }
  )
}

export async function importVehiclesCsv(input: { fileName: string; csv: string }) {
  return withAuth(
    async ({ userId, organizationId }) => {
      if (!input.fileName.toLowerCase().endsWith('.csv'))
        throw new Error('Please select a CSV file')
      if (input.csv.length > 2_000_000) throw new Error('CSV file is too large')

      const normalized = normalizeVehicleCsv(input.csv)
      const existing = await db.vehicle.findMany({
        where: { organizationId },
        select: {
          id: true,
          trackingExternalId: true,
          vin: true,
          licensePlate: true,
          make: true,
          model: true,
          year: true,
          mileage: true,
        },
      })

      const byExternalId = new Map(
        existing
          .filter((vehicle) => vehicle.trackingExternalId)
          .map((vehicle) => [vehicle.trackingExternalId!.toUpperCase(), vehicle])
      )
      const byVin = new Map(
        existing
          .filter((vehicle) => vehicle.vin)
          .map((vehicle) => [vehicle.vin!.toUpperCase(), vehicle])
      )
      const byPlate = new Map(
        existing
          .filter((vehicle) => vehicle.licensePlate)
          .map((vehicle) => [vehicle.licensePlate!.toUpperCase(), vehicle])
      )

      let created = 0
      let updated = 0

      await db.$transaction(
        async (tx) => {
          for (const vehicle of normalized.vehicles) {
            const match =
              byExternalId.get(vehicle.externalId.toUpperCase()) ??
              (vehicle.vin ? byVin.get(vehicle.vin.toUpperCase()) : undefined) ??
              (vehicle.licensePlate ? byPlate.get(vehicle.licensePlate.toUpperCase()) : undefined)

            if (match) {
              await tx.vehicle.update({
                where: { id: match.id },
                data: {
                  assetType: vehicle.assetType,
                  vin: match.vin || vehicle.vin,
                  licensePlate: match.licensePlate || vehicle.licensePlate,
                  mileage:
                    vehicle.mileage > 0 ? Math.max(match.mileage, vehicle.mileage) : match.mileage,
                  trackingProvider: vehicle.source === 'map-assets' ? 'skybitz' : 'samsara',
                  trackingExternalId: match.trackingExternalId || vehicle.externalId,
                  trackingAddress: vehicle.trackingAddress,
                  trackingStatus: vehicle.trackingStatus,
                  trackingLastSeenAt: vehicle.trackingLastSeenAt,
                  trackingCargoStatus: vehicle.trackingCargoStatus,
                  trackingSpeed: vehicle.trackingSpeed,
                  trackingHeading: vehicle.trackingHeading,
                },
              })
              updated += 1
              continue
            }

            const createdVehicle = await tx.vehicle.create({
              data: {
                assetType: vehicle.assetType,
                make: vehicle.make,
                model: vehicle.model,
                year: vehicle.year,
                vin: vehicle.vin,
                licensePlate: vehicle.licensePlate,
                mileage: vehicle.mileage,
                fuelType: vehicle.assetType === 'truck' ? 'diesel' : 'other',
                transmission: vehicle.assetType === 'truck' ? 'automatic' : null,
                userId,
                organizationId,
                trackingProvider: vehicle.source === 'map-assets' ? 'skybitz' : 'samsara',
                trackingExternalId: vehicle.externalId,
                trackingAddress: vehicle.trackingAddress,
                trackingStatus: vehicle.trackingStatus,
                trackingLastSeenAt: vehicle.trackingLastSeenAt,
                trackingCargoStatus: vehicle.trackingCargoStatus,
                trackingSpeed: vehicle.trackingSpeed,
                trackingHeading: vehicle.trackingHeading,
              },
            })
            byExternalId.set(vehicle.externalId.toUpperCase(), createdVehicle)
            if (vehicle.vin) byVin.set(vehicle.vin.toUpperCase(), createdVehicle)
            if (vehicle.licensePlate)
              byPlate.set(vehicle.licensePlate.toUpperCase(), createdVehicle)
            created += 1
          }
        },
        { maxWait: 10_000, timeout: 120_000 }
      )

      revalidatePath('/')
      revalidatePath('/vehicles')
      revalidatePath('/tracking')
      return {
        source: normalized.kind,
        total: normalized.vehicles.length,
        created,
        updated,
        skipped: normalized.skipped,
      }
    },
    {
      requiredPermissions: [
        { action: PermissionAction.CREATE, subject: PermissionSubject.VEHICLES },
        { action: PermissionAction.UPDATE, subject: PermissionSubject.VEHICLES },
      ],
    }
  )
}

export async function updateVehicle(input: unknown) {
  return withAuth(
    async ({ organizationId, userId }) => {
      const { id, ...data } = updateVehicleSchema.parse(input)

      // Fetch current record for display/diff
      const before = await db.vehicle.findFirst({
        where: { id, organizationId },
        select: { year: true, make: true, model: true, licensePlate: true },
      })
      if (!before) throw new Error('Vehicle not found')

      // If image is being changed, delete the old file from disk
      if (data.imageUrl !== undefined) {
        const existing = await db.vehicle.findFirst({
          where: { id, organizationId },
          select: { imageUrl: true },
        })
        if (existing?.imageUrl && existing.imageUrl !== data.imageUrl) {
          try {
            await unlink(resolveUploadPath(existing.imageUrl))
          } catch {
            // Old file may already be gone
          }
        }
      }

      const updateResult = await db.vehicle.updateMany({
        where: { id, organizationId },
        data: {
          ...data,
          vin: data.vin !== undefined ? data.vin || null : undefined,
          licensePlate: data.licensePlate !== undefined ? data.licensePlate || null : undefined,
          color: data.color !== undefined ? data.color || null : undefined,
          fuelType: data.fuelType !== undefined ? data.fuelType || null : undefined,
          transmission: data.transmission !== undefined ? data.transmission || null : undefined,
          engineSize: data.engineSize !== undefined ? data.engineSize || null : undefined,
          engineCode: data.engineCode !== undefined ? data.engineCode || null : undefined,
          purchaseDate: data.purchaseDate ? new Date(data.purchaseDate) : undefined,
          customerId: data.customerId !== undefined ? data.customerId || null : undefined,
        },
      })
      if (updateResult.count === 0) throw new Error('Vehicle not found')
      const vehicleDisplay = `${before.year} ${before.make} ${before.model}${before.licensePlate ? ` (${before.licensePlate})` : ''}`
      const changedKeys = Object.keys(data).filter(
        (k) => (data as Record<string, unknown>)[k] !== undefined
      )
      revalidatePath('/')
      revalidatePath('/vehicles')
      revalidatePath(`/vehicles/${id}`)
      revalidatePath('/tracking')
      return { id, count: updateResult.count, fields: changedKeys, vehicleDisplay }
    },
    {
      requiredPermissions: [
        { action: PermissionAction.UPDATE, subject: PermissionSubject.VEHICLES },
      ],
      audit: ({ result }) => ({
        action: 'vehicle.update',
        entity: 'Vehicle',
        entityId: result.id,
        message: `Updated vehicle ${result.vehicleDisplay} — changed: ${result.fields.join(', ') || '(no changes)'}`,
        metadata: {
          vehicleId: result.id,
          vehicleDisplay: result.vehicleDisplay,
          changed: result.fields,
        },
      }),
    }
  )
}

export async function deleteVehicle(vehicleId: string) {
  return withAuth(
    async ({ organizationId, userId }) => {
      // Fetch vehicle with its attachments so we can clean up files
      const vehicle = await db.vehicle.findFirst({
        where: { id: vehicleId, organizationId },
        select: {
          imageUrl: true,
          year: true,
          make: true,
          model: true,
          licensePlate: true,
          serviceRecords: {
            select: { attachments: { select: { fileUrl: true } } },
          },
        },
      })
      if (!vehicle) throw new Error('Vehicle not found')

      await db.vehicle.deleteMany({ where: { id: vehicleId, organizationId } })

      // Clean up files from disk after DB deletion
      if (vehicle) {
        const filesToDelete: string[] = []
        if (vehicle.imageUrl) filesToDelete.push(vehicle.imageUrl)
        for (const sr of vehicle.serviceRecords) {
          for (const att of sr.attachments) {
            filesToDelete.push(att.fileUrl)
          }
        }
        for (const fileUrl of filesToDelete) {
          try {
            await unlink(resolveUploadPath(fileUrl))
          } catch {
            // File may already be gone
          }
        }
      }

      const vehicleDisplay = `${vehicle.year} ${vehicle.make} ${vehicle.model}${vehicle.licensePlate ? ` (${vehicle.licensePlate})` : ''}`
      revalidatePath('/')
      revalidatePath('/vehicles')
      revalidatePath('/tracking')
      return { vehicleId, vehicleDisplay }
    },
    {
      requiredPermissions: [
        { action: PermissionAction.DELETE, subject: PermissionSubject.VEHICLES },
      ],
      audit: ({ result }) => ({
        action: 'vehicle.delete',
        entity: 'Vehicle',
        entityId: result.vehicleId,
        message: `Deleted vehicle ${result.vehicleDisplay}`,
        metadata: { vehicleId: result.vehicleId, vehicleDisplay: result.vehicleDisplay },
      }),
    }
  )
}

export async function searchVehicles(search?: string, limit = 20, offset = 0) {
  return withAuth(
    async ({ organizationId }) => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const where: any = { organizationId, isArchived: false }
      if (search) {
        const words = search.trim().split(/\s+/).filter(Boolean)
        const fieldMatch = (word: string) => {
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          const conditions: any[] = [
            { make: { contains: word, mode: 'insensitive' } },
            { model: { contains: word, mode: 'insensitive' } },
            { licensePlate: { contains: word, mode: 'insensitive' } },
            { vin: { contains: word, mode: 'insensitive' } },
            { customer: { name: { contains: word, mode: 'insensitive' } } },
          ]
          if (!isNaN(Number(word))) {
            conditions.push({ year: Number(word) })
          }
          return conditions
        }
        if (words.length > 1) {
          where.AND = words.map((word) => ({ OR: fieldMatch(word) }))
        } else {
          where.OR = fieldMatch(words[0])
        }
      }
      return db.vehicle.findMany({
        where,
        select: {
          id: true,
          make: true,
          model: true,
          year: true,
          licensePlate: true,
          customerId: true,
          customer: { select: { id: true, name: true } },
        },
        orderBy: { updatedAt: 'desc' },
        skip: offset,
        take: limit,
      })
    },
    {
      requiredPermissions: [{ action: PermissionAction.READ, subject: PermissionSubject.VEHICLES }],
    }
  )
}
