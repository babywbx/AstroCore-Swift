import Foundation
import Testing

@testable import AstroCore

// Phase 2: Porphyry + Sripati tests.

@Suite("Porphyry houses")
struct PorphyryHousesTests {
    private func defaultContext() throws -> (CivilMoment, GeoCoordinate) {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 40.0, longitude: 0.0)
        return (moment, coord)
    }

    @Test func anglesAlignToCusps1_4_7_10() throws {
        let (moment, coord) = try defaultContext()
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .porphyry
        )
        #expect(abs(result.cusps[0].eclipticLongitude - result.angles.ascendant) < 1e-9)
        #expect(abs(result.cusps[3].eclipticLongitude - result.angles.imumCoeli) < 1e-9)
        #expect(abs(result.cusps[6].eclipticLongitude - result.angles.descendant) < 1e-9)
        #expect(abs(result.cusps[9].eclipticLongitude - result.angles.midheaven) < 1e-9)
    }

    @Test func quadrantsTrisectedEqually() throws {
        let (moment, coord) = try defaultContext()
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .porphyry
        )
        // Cusps 1-4 (ASC → IC): house 1, 2, 3 should be equal width.
        let quadrants: [Range<Int>] = [0..<3, 3..<6, 6..<9, 9..<12]
        for q in quadrants {
            let c0 = result.cusps[q.lowerBound].eclipticLongitude
            let c1 = result.cusps[q.lowerBound + 1].eclipticLongitude
            let c2 = result.cusps[q.lowerBound + 2].eclipticLongitude
            let nextQuadrantStart = result.cusps[(q.upperBound) % 12].eclipticLongitude
            let arc1 = AngleMath.normalized(degrees: c1 - c0)
            let arc2 = AngleMath.normalized(degrees: c2 - c1)
            let arc3 = AngleMath.normalized(degrees: nextQuadrantStart - c2)
            #expect(abs(arc1 - arc2) < 1e-9, "Quadrant \(q): arc1=\(arc1), arc2=\(arc2)")
            #expect(abs(arc2 - arc3) < 1e-9, "Quadrant \(q): arc2=\(arc2), arc3=\(arc3)")
        }
    }

    @Test func totalArcsSumTo360() throws {
        let (moment, coord) = try defaultContext()
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .porphyry
        )
        var total = 0.0
        for i in 0..<12 {
            let delta = AngleMath.normalized(
                degrees: result.cusps[(i + 1) % 12].eclipticLongitude
                    - result.cusps[i].eclipticLongitude
            )
            total += delta
        }
        #expect(abs(total - 360.0) < 1e-9)
    }

    @Test func highLatitudeQuadrantSkew() throws {
        // At high latitude the MC→ASC arc shrinks dramatically while IC→DSC
        // grows. Porphyry should still trisect each quadrant regardless.
        // Use an off-meridian time so the configuration is asymmetric.
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 15, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 60.0, longitude: 45.0)
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .porphyry
        )
        // At least one quadrant arc must differ from 90° by > 5° (skew confirmed),
        // yet Porphyry must still hold cusps 1/4/7/10 exactly on the angles.
        let arcs = [
            AngleMath.normalized(
                degrees: result.angles.imumCoeli - result.angles.ascendant),
            AngleMath.normalized(
                degrees: result.angles.descendant - result.angles.imumCoeli),
            AngleMath.normalized(
                degrees: result.angles.midheaven - result.angles.descendant),
            AngleMath.normalized(
                degrees: result.angles.ascendant - result.angles.midheaven),
        ]
        let maxDeviation = arcs.map { abs($0 - 90.0) }.max() ?? 0
        #expect(maxDeviation > 5.0, "Expected high-latitude quadrant skew")
        #expect(abs(result.cusps[0].eclipticLongitude - result.angles.ascendant) < 1e-9)
        #expect(abs(result.cusps[9].eclipticLongitude - result.angles.midheaven) < 1e-9)
    }
}

@Suite("Sripati houses")
struct SripatiHousesTests {
    private func defaultContext() throws -> (CivilMoment, GeoCoordinate) {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 28.6, longitude: 77.2)  // Delhi
        return (moment, coord)
    }

    @Test func sripatiCuspsAreMidpointsOfPorphyry() throws {
        let (moment, coord) = try defaultContext()
        let porphyry = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .porphyry
        )
        let sripati = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .sripati
        )
        for i in 0..<12 {
            let start = porphyry.cusps[i].eclipticLongitude
            let end = porphyry.cusps[(i + 1) % 12].eclipticLongitude
            let forwardArc = AngleMath.normalized(degrees: end - start)
            let expectedMid = AngleMath.normalized(degrees: start + forwardArc / 2.0)
            #expect(
                abs(sripati.cusps[i].eclipticLongitude - expectedMid) < 1e-9,
                "Sripati cusp \(i+1) off-midpoint"
            )
        }
    }

    @Test func sripatiAndPorphyryOffsetByHalfHouse() throws {
        let (moment, coord) = try defaultContext()
        let porphyry = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .porphyry
        )
        let sripati = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .sripati
        )
        // Each Sripati cusp sits BETWEEN two Porphyry cusps — so a Sripati
        // cusp must be strictly between Porphyry cusp n and n+1 (circular).
        for i in 0..<12 {
            let s = sripati.cusps[i].eclipticLongitude
            let p0 = porphyry.cusps[i].eclipticLongitude
            let p1 = porphyry.cusps[(i + 1) % 12].eclipticLongitude
            let fromP0 = AngleMath.normalized(degrees: s - p0)
            let fromP1 = AngleMath.normalized(degrees: p1 - s)
            #expect(fromP0 > 0 && fromP1 > 0)
        }
    }

    @Test func sripatiPartitionSumsTo360() throws {
        let (moment, coord) = try defaultContext()
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .sripati
        )
        var total = 0.0
        for i in 0..<12 {
            total += AngleMath.normalized(
                degrees: result.cusps[(i + 1) % 12].eclipticLongitude
                    - result.cusps[i].eclipticLongitude
            )
        }
        #expect(abs(total - 360.0) < 1e-9)
    }
}
