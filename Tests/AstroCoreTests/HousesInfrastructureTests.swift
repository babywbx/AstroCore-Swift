import Foundation
import Testing

@testable import AstroCore

// Phase 0: Houses infrastructure tests.
// Covers MC formula, Angles struct, router, polar fallback, and the four
// equal-division systems.

@Suite("MC formula")
struct MidheavenFormulaTests {
    // Cardinal LAST: MC coincides with LAST exactly (obliquity drops out).
    @Test func mcAtCardinalLast() {
        let epsilon = 23.4393
        #expect(
            abs(
                AnglesEngine.midheavenLongitude(
                    lastDegrees: 0, trueObliquityDegrees: epsilon
                ) - 0.0
            ) < 1e-9
        )
        #expect(
            abs(
                AnglesEngine.midheavenLongitude(
                    lastDegrees: 90, trueObliquityDegrees: epsilon
                ) - 90.0
            ) < 1e-9
        )
        #expect(
            abs(
                AnglesEngine.midheavenLongitude(
                    lastDegrees: 180, trueObliquityDegrees: epsilon
                ) - 180.0
            ) < 1e-9
        )
        let mc270 = AnglesEngine.midheavenLongitude(
            lastDegrees: 270, trueObliquityDegrees: epsilon
        )
        #expect(abs(mc270 - 270.0) < 1e-9)
    }

    // Defining identity: tan(λ_MC) × cos(ε) = tan(ARMC) (with matching quadrant).
    // Verify for a sweep of non-singular ARMC values.
    @Test func mcSatisfiesDefiningIdentity() {
        let epsilon = 23.4393
        let cosEps = TrigDeg.cos(epsilon)
        for armc in stride(from: 5.0, through: 355.0, by: 7.0) where
            abs(armc - 90.0) > 1e-3 && abs(armc - 270.0) > 1e-3
        {
            let mc = AnglesEngine.midheavenLongitude(
                lastDegrees: armc, trueObliquityDegrees: epsilon
            )
            let lhs = TrigDeg.tan(mc) * cosEps
            let rhs = TrigDeg.tan(armc)
            #expect(
                abs(lhs - rhs) < 1e-9,
                "Identity fails at ARMC=\(armc)°, MC=\(mc)° (Δ=\(lhs - rhs))"
            )
        }
    }

    // MC must always lie in the hemisphere (0-180 vs 180-360) consistent with LAST.
    @Test func mcHemisphereConsistency() {
        let epsilon = 23.4393
        for armc in stride(from: 5.0, to: 360.0, by: 15.0) {
            let mc = AnglesEngine.midheavenLongitude(
                lastDegrees: armc, trueObliquityDegrees: epsilon
            )
            let armcUpperHalf = armc < 180.0
            let mcUpperHalf = mc < 180.0
            // Poles of the formula (LAST = 0°, 180°) skipped via stride.
            #expect(
                armcUpperHalf == mcUpperHalf,
                "MC quadrant mismatch at ARMC=\(armc)°, MC=\(mc)°"
            )
        }
    }
}

@Suite("Angles struct")
struct AnglesStructTests {
    @Test func oppositeAxesAreOpposing() {
        let angles = Angles(ascendant: 42.0, midheaven: 330.0, vertex: nil)
        #expect(abs(angles.descendant - 222.0) < 1e-9)
        #expect(abs(angles.imumCoeli - 150.0) < 1e-9)
    }

    @Test func opposeWrapsAtBoundary() {
        let angles = Angles(ascendant: 200.0, midheaven: 100.0, vertex: nil)
        #expect(abs(angles.descendant - 20.0) < 1e-9)
        #expect(abs(angles.imumCoeli - 280.0) < 1e-9)
    }
}

@Suite("Whole Sign houses")
struct WholeSignTests {
    @Test func cuspsAlignToSignBoundaries() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 51.5, longitude: 0.0)

        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .wholeSign
        )
        #expect(result.cusps.count == 12)
        #expect(result.resolvedSystem == .wholeSign)
        // Every Whole Sign cusp sits at degree 0 of some sign.
        for cusp in result.cusps {
            #expect(cusp.degreeInSign < 1e-9 || cusp.degreeInSign > 30.0 - 1e-9)
        }
        // The ASC sign is the 1st house.
        let ascSign = ZodiacMapper.details(
            forNormalizedLongitude: result.angles.ascendant
        ).sign
        #expect(result.cusps[0].sign == ascSign)
    }
}

@Suite("Equal-division houses")
struct EqualDivisionTests {
    private func makeContext() throws -> (CivilMoment, GeoCoordinate) {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 40.7, longitude: -74.0)
        return (moment, coord)
    }

    @Test func equalAscStartsAtAscendant() throws {
        let (moment, coord) = try makeContext()
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .equalASC
        )
        #expect(abs(result.cusps[0].eclipticLongitude - result.angles.ascendant) < 1e-9)
        // Spacing = 30° exactly.
        for i in 0..<11 {
            let delta = AngleMath.normalized(
                degrees: result.cusps[i + 1].eclipticLongitude
                    - result.cusps[i].eclipticLongitude
            )
            #expect(abs(delta - 30.0) < 1e-9)
        }
    }

    @Test func equalMcPlacesMcAtCusp10() throws {
        let (moment, coord) = try makeContext()
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .equalMC
        )
        let cusp10 = result.cusps[9].eclipticLongitude
        let mc = result.angles.midheaven
        #expect(abs(AngleMath.normalized(degrees: cusp10 - mc)) < 1e-9)
    }

    @Test func vehlowPlacesAscMidHouse() throws {
        let (moment, coord) = try makeContext()
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .vehlow
        )
        // ASC sits 15° past cusp 1.
        let offset = AngleMath.normalized(
            degrees: result.angles.ascendant - result.cusps[0].eclipticLongitude
        )
        #expect(abs(offset - 15.0) < 1e-9)
    }
}

@Suite("House engine routing")
struct HouseEngineRoutingTests {
    @Test func unimplementedSystemThrows() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 0.0, longitude: 0.0)
        do {
            _ = try AstroCalculator.houses(
                for: moment, coordinate: coord, system: .placidus
            )
            Issue.record("Expected .houseSystemNotYetImplemented")
        } catch {
            if case .houseSystemNotYetImplemented(let s) = error {
                #expect(s == .placidus)
            } else {
                Issue.record("Unexpected error: \(error)")
            }
        }
    }

    // Equator latitude must still produce all systems that don't have polar limits.
    @Test func equalSystemsSucceedAtEquator() throws {
        let moment = try CivilMoment(
            year: 2000, month: 3, day: 21,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 0.0, longitude: 0.0)
        for system: HouseSystem in [.wholeSign, .equalASC, .equalMC, .vehlow] {
            let result = try AstroCalculator.houses(
                for: moment, coordinate: coord, system: system
            )
            #expect(result.cusps.count == 12)
            #expect(result.resolvedSystem == system)
        }
    }
}

@Suite("Polar fallback")
struct PolarFallbackTests {
    @Test func placidusFallsBackAtHighLatitude() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        // Latitude 80° N is inside the polar circle but below the ASC 85° limit.
        let coord = try GeoCoordinate(latitude: 80.0, longitude: 0.0)
        let result = try AstroCalculator.houses(
            for: moment,
            coordinate: coord,
            system: .placidus,
            polarFallback: .equalASC
        )
        #expect(result.requestedSystem == .placidus)
        #expect(result.resolvedSystem == .equalASC)
        #expect(!result.usedRequestedSystem)
    }

    @Test func errorFallbackThrowsInPolarZone() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 80.0, longitude: 0.0)
        do {
            _ = try AstroCalculator.houses(
                for: moment,
                coordinate: coord,
                system: .placidus,
                polarFallback: .error
            )
            Issue.record("Expected .houseSystemUndefinedAtLatitude")
        } catch {
            if case .houseSystemUndefinedAtLatitude(let s, _) = error {
                #expect(s == .placidus)
            } else {
                Issue.record("Unexpected error: \(error)")
            }
        }
    }

    @Test func nonLimitedSystemIgnoresLatitude() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 80.0, longitude: 0.0)
        // Whole Sign has no polar limit, so it must succeed at 80°.
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .wholeSign
        )
        #expect(result.resolvedSystem == .wholeSign)
    }
}

@Suite("Semi-arc helper")
struct SemiArcTests {
    // At the equator, every ecliptic point has SA = 90° (12h daylight regardless
    // of declination), because tan(0°) = 0 makes the cos(H) formula yield 90°.
    @Test func semiArcAtEquatorIs90Degrees() {
        for lon in stride(from: 0.0, through: 330.0, by: 30.0) {
            let result = SemiArc.compute(
                eclipticLongitude: lon, obliquity: 23.4393, latitude: 0.0
            )
            #expect(!result.isCircumpolar)
            if let sa = result.semiDiurnalArc {
                #expect(abs(sa - 90.0) < 1e-9, "SA at equator, λ=\(lon) was \(sa)")
            }
        }
    }

    // Summer solstice point (λ=90°) viewed from latitude 70° N is circumpolar
    // (midnight sun), because sin(δ) = sin(23.44°) = 0.398, |tan(70°)×tan(δ)| ≈ 1.19 > 1.
    @Test func summerSolsticeIsCircumpolarAt70NorthLat() {
        let result = SemiArc.compute(
            eclipticLongitude: 90.0, obliquity: 23.4393, latitude: 70.0
        )
        #expect(result.isCircumpolar)
        #expect(result.semiDiurnalArc == nil)
    }
}

@Suite("Natal chart composition")
struct NatalChartTests {
    @Test func natalChartPackagesPlanetsAndHouses() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 51.5, longitude: 0.0)
        let chart = try AstroCalculator.natalChart(
            for: moment,
            coordinate: coord,
            bodies: [.sun, .moon],
            system: .wholeSign
        )
        #expect(chart.positions.bodies.count == 2)
        #expect(chart.houses.cusps.count == 12)
        #expect(chart.houses.angles.ascendant == chart.positions.ascendant?.eclipticLongitude)
    }
}
