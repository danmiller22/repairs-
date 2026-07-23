import { describe, expect, it } from 'vitest'
import {
  getPremierLegacyCargoStatus,
  getSkyBitzCargoStatus,
  normalizeTrackingCargoStatus,
} from '@/features/tracking/Lib/cargo-status'

describe('tracking cargo status normalization', () => {
  it.each([
    ['Loaded', 'loaded'],
    ['Full', 'loaded'],
    ['(Loaded)', 'loaded'],
    ['Empty', 'empty'],
    ['Unloaded', 'empty'],
    ['(Empty)', 'empty'],
    ['In Transition', 'unknown'],
    ['Undetermined', 'unknown'],
    [undefined, 'unknown'],
  ])('normalizes %s to %s', (input, expected) => {
    expect(normalizeTrackingCargoStatus(input)).toBe(expected)
  })

  it('reads the cargo serial device from a SkyBitz position', () => {
    expect(
      getSkyBitzCargoStatus({
        serial: [
          { serialtype: '2', serialname: 'Motion', serialdata: 'Moving' },
          { serialtype: '1', serialname: 'Cargo', serialdata: 'Loaded' },
        ],
      })
    ).toBe('loaded')
  })

  it('accepts a single SkyBitz cargo serial object', () => {
    expect(
      getSkyBitzCargoStatus({
        serial: { serialtype: '1', serialdata: 'Empty' },
      })
    ).toBe('empty')
  })

  it('returns unknown when a SkyBitz position only contains motion data', () => {
    expect(
      getSkyBitzCargoStatus({
        serial: { serialtype: '2', serialname: 'Motion', serialdata: 'Idle' },
      })
    ).toBe('unknown')
  })

  it('reads FleetLocate cargo only when the sensor is enabled', () => {
    expect(getPremierLegacyCargoStatus({ cargoOn: true, cargoLoaded: true })).toBe('loaded')
    expect(getPremierLegacyCargoStatus({ cargoOn: true, cargoLoaded: false })).toBe('empty')
    expect(getPremierLegacyCargoStatus({ cargoOn: false, cargoLoaded: true })).toBe('unknown')
  })
})
