import { describe, expect, it } from 'vitest'
import { normalizeVehicleCsv, parseCsv } from './vehicleCsvImport'

describe('vehicle CSV import', () => {
  it('parses quoted commas', () => {
    expect(parseCsv('Name,Location\n12,"Chicago, IL"\n')).toEqual([
      { Name: '12', Location: 'Chicago, IL' },
    ])
  })

  it('normalizes Map Assets trailers', () => {
    const result = normalizeVehicleCsv(
      'Asset ID,Status,Location,Total Mileage (mi),Cargo Status,Speed,Heading\nPTLZ262305,Moving,"Macon, GA","63,911",Empty,55,N\n'
    )

    expect(result.kind).toBe('map-assets')
    expect(result.vehicles[0]).toMatchObject({
      externalId: 'PTLZ262305',
      assetType: 'trailer',
      year: 2026,
      mileage: 63911,
      trackingAddress: 'Macon, GA',
    })
  })

  it('normalizes Samsara tractors and skips gateway-only rows', () => {
    const result = normalizeVehicleCsv(
      'Name,Gateway Serial,License Plate,VIN,Odometer (mi),Last Connected,Last Location\n7969,GYZV-AUB-YNE,P1096871,4V4NC9EHXNN297969,770783.6,24 Jul 2026 10:40,"Ridley Township, PA"\nG5EM-JSU-9U2,G5EM-JSU-9U2,n/a,,n/a,n/a,Location unknown\n'
    )

    expect(result.skipped).toBe(1)
    expect(result.vehicles[0]).toMatchObject({
      externalId: '7969',
      assetType: 'truck',
      make: 'Volvo',
      year: 2022,
      vin: '4V4NC9EHXNN297969',
    })
  })
})
