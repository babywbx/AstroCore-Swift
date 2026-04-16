import Foundation
import Testing

@testable import AstroCore

// Phase 3: Placidus, Koch, Regiomontanus, Campanus.
//
// These tests pin invariants that must hold for any correct implementation:
// (1) angles land on cusps 1/4/7/10, (2) opposite cusps differ by 180°,
// (3) cusps partition the full ecliptic (sum of forward arcs = 360°), and
// (4) cusp order is monotonic.
//
// Numerical cross-checks against Swiss Ephemeris will be added in a later
// phase; here we validate structure, not absolute precision.

private enum Fixtures {
    static let quadrantSystems: [HouseSystem] = [
        .placidus, .koch, .regiomontanus, .campanus
    ]

    static func londonMoment() throws -> CivilMoment {
        try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 18, minute: 30,
            timeZoneIdentifier: "UTC"
        )
    }
    static func london() throws -> GeoCoordinate {
        try GeoCoordinate(latitude: 51.5, longitude: -0.13)
    }

    static func sydneyMoment() throws -> CivilMoment {
        try CivilMoment(
            year: 2010, month: 12, day: 15,
            hour: 9, minute: 0,
            timeZoneIdentifier: "Australia/Sydney"
        )
    }
    static func sydney() throws -> GeoCoordinate {
        try GeoCoordinate(latitude: -33.87, longitude: 151.21)
    }
}

@Suite("Phase 3 invariants (Placidus, Koch, Regiomontanus, Campanus)")
struct QuadrantHousesInvariantTests {
    private func invariants(
        for result: HouseResult,
        system: HouseSystem,
        tolerance: Double = 1e-7
    ) {
        // Angles align to cusps 1, 4, 7, 10.
        #expect(
            abs(result.cusps[0].eclipticLongitude - result.angles.ascendant) < tolerance,
            "\(system): cusp 1 ≠ ASC"
        )
        #expect(
            abs(result.cusps[3].eclipticLongitude - result.angles.imumCoeli) < tolerance,
            "\(system): cusp 4 ≠ IC"
        )
        #expect(
            abs(result.cusps[6].eclipticLongitude - result.angles.descendant) < tolerance,
            "\(system): cusp 7 ≠ DSC"
        )
        #expect(
            abs(result.cusps[9].eclipticLongitude - result.angles.midheaven) < tolerance,
            "\(system): cusp 10 ≠ MC"
        )

        // Opposite cusps differ by 180°.
        for i in 0..<6 {
            let diff = AngleMath.normalized(
                degrees: result.cusps[i + 6].eclipticLongitude
                    - result.cusps[i].eclipticLongitude
            )
            #expect(
                abs(diff - 180.0) < tolerance,
                "\(system): cusp \(i+7) − cusp \(i+1) = \(diff)"
            )
        }

        // Forward arcs sum to 360°.
        var total = 0.0
        for i in 0..<12 {
            total += AngleMath.normalized(
                degrees: result.cusps[(i + 1) % 12].eclipticLongitude
                    - result.cusps[i].eclipticLongitude
            )
        }
        #expect(
            abs(total - 360.0) < tolerance,
            "\(system): forward arcs total = \(total)"
        )

        // Each forward arc is strictly positive (cusps don't cross).
        for i in 0..<12 {
            let arc = AngleMath.normalized(
                degrees: result.cusps[(i + 1) % 12].eclipticLongitude
                    - result.cusps[i].eclipticLongitude
            )
            #expect(arc > 0.0 && arc < 360.0, "\(system): cusp \(i+1) arc = \(arc)")
        }
    }

    @Test func londonChartHonoursInvariants() throws {
        let moment = try Fixtures.londonMoment()
        let coord = try Fixtures.london()
        for system in Fixtures.quadrantSystems {
            let result = try AstroCalculator.houses(
                for: moment, coordinate: coord, system: system
            )
            #expect(result.resolvedSystem == system)
            invariants(for: result, system: system)
        }
    }

    @Test func sydneyChartHonoursInvariants() throws {
        let moment = try Fixtures.sydneyMoment()
        let coord = try Fixtures.sydney()
        for system in Fixtures.quadrantSystems {
            let result = try AstroCalculator.houses(
                for: moment, coordinate: coord, system: system
            )
            #expect(result.resolvedSystem == system)
            invariants(for: result, system: system)
        }
    }

    @Test func systemsProduceDistinctCusps() throws {
        let moment = try Fixtures.londonMoment()
        let coord = try Fixtures.london()
        var cuspMatrix: [HouseSystem: [Double]] = [:]
        for system in Fixtures.quadrantSystems {
            let result = try AstroCalculator.houses(
                for: moment, coordinate: coord, system: system
            )
            cuspMatrix[system] = result.cusps.map(\.eclipticLongitude)
        }
        // Intermediate cusps (not 1, 4, 7, 10) must differ between systems.
        for (s1, c1) in cuspMatrix {
            for (s2, c2) in cuspMatrix where s1 != s2 {
                let maxDiff = zip(c1, c2).enumerated().map { i, pair -> Double in
                    guard [1, 2, 4, 5, 7, 8, 10, 11].contains(i) else { return 0 }
                    var d = abs(pair.0 - pair.1)
                    if d > 180 { d = 360 - d }
                    return d
                }.max() ?? 0
                #expect(maxDiff > 0.1, "\(s1) and \(s2) produce near-identical cusps")
            }
        }
    }
}

@Suite("Placidus convergence and fallback")
struct PlacidusSpecificTests {
    @Test func convergesAtMidLatitudes() throws {
        // Sweep across representative cases to confirm the iterator always
        // converges and produces the expected invariants.
        let moment = try CivilMoment(
            year: 1984, month: 10, day: 24,
            hour: 3, minute: 15,
            timeZoneIdentifier: "UTC"
        )
        for lat in [0.0, 23.5, 45.0, 55.0, 65.0, -30.0, -55.0] {
            let coord = try GeoCoordinate(latitude: lat, longitude: 0.0)
            let result = try AstroCalculator.houses(
                for: moment, coordinate: coord, system: .placidus
            )
            #expect(result.cusps.count == 12)
            #expect(result.resolvedSystem == .placidus)
        }
    }

    @Test func fallsBackAtArcticLatitude() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 75.0, longitude: 0.0)
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .placidus,
            polarFallback: .porphyry
        )
        #expect(result.requestedSystem == .placidus)
        #expect(result.resolvedSystem == .porphyry)
    }
}

@Suite("Koch-specific checks")
struct KochSpecificTests {
    @Test func kochFallsBackAboveArctic() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 70.0, longitude: 0.0)
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .koch,
            polarFallback: .equalASC
        )
        #expect(result.resolvedSystem == .equalASC)
    }

    @Test func kochDiffersFromPlacidusSlightly() throws {
        // Near the arctic circle the two systems diverge more visibly; at mid
        // latitudes they're similar but never identical.
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 18, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 55.0, longitude: 0.0)
        let koch = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .koch
        )
        let placidus = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .placidus
        )
        let intermediate = [1, 2, 4, 5, 7, 8, 10, 11]
        var maxDiff = 0.0
        for i in intermediate {
            var d = abs(koch.cusps[i].eclipticLongitude - placidus.cusps[i].eclipticLongitude)
            if d > 180 { d = 360 - d }
            maxDiff = max(maxDiff, d)
        }
        #expect(maxDiff > 0.01)
    }
}

@Suite("Regiomontanus and Campanus cross-checks")
struct ProjectionHousesTests {
    @Test func regiomontanusAndCampanusDifferAtMidLatitude() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 18, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 45.0, longitude: 0.0)
        let reg = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .regiomontanus
        )
        let cam = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .campanus
        )
        // Non-trivial difference on intermediate cusps.
        var maxDiff = 0.0
        for i in [1, 2, 4, 5, 7, 8, 10, 11] {
            var d = abs(reg.cusps[i].eclipticLongitude - cam.cusps[i].eclipticLongitude)
            if d > 180 { d = 360 - d }
            maxDiff = max(maxDiff, d)
        }
        #expect(maxDiff > 0.1)
    }

    @Test func regiomontanusSystemsWorkAtArctic() throws {
        // Regiomontanus/Campanus don't have a clean polar limit (no semi-arc
        // iteration), so they should continue to produce cusps well inside
        // latitudes that trip Placidus/Koch.
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 75.0, longitude: 0.0)
        for system in [HouseSystem.regiomontanus, .campanus] {
            let result = try AstroCalculator.houses(
                for: moment, coordinate: coord, system: system
            )
            #expect(result.resolvedSystem == system)
        }
    }
}
