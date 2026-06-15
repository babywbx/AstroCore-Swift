@testable import AstroCore
import Foundation
import Testing

@Suite("Aspect Exact Moment")
struct AspectExactMomentTests {
    private static let j2000TT = 2451545.0

    private static func separation(
        _ a: CelestialBody, _ b: CelestialBody, _ phi: Double, jdTT: Double
    ) -> Double {
        let la = AstroCalculator.eclipticLongitude(of: a, julianDayTT: jdTT)
        let lb = AstroCalculator.eclipticLongitude(of: b, julianDayTT: jdTT)
        return AstroCalculator.aspectSeparation(
            longitudeA: la, longitudeB: lb, aspectAngleDegrees: phi
        )
    }

    @Test func exactConjunctionSatisfiesAngleInvariant() throws {
        let tStar = try #require(
            AstroCalculator.exactAspectJulianDayTT(
                of: .sun, and: .moon, aspectAngleDegrees: 0, nearJulianDayTT: Self.j2000TT
            )
        )
        #expect(abs(tStar - Self.j2000TT) <= 60.0)
        #expect(abs(Self.separation(.sun, .moon, 0, jdTT: tStar)) < 1e-7)
    }

    @Test func exactAspectAtCurrentSeparationSitsAtSeedEpoch() throws {
        // phi = current shortest-arc separation -> a root must sit at ~the seed JD.
        let phi = Self.separation(.saturn, .pluto, 0, jdTT: Self.j2000TT)
        let tStar = try #require(
            AstroCalculator.exactAspectJulianDayTT(
                of: .saturn, and: .pluto, aspectAngleDegrees: phi, nearJulianDayTT: Self.j2000TT
            )
        )
        #expect(abs(tStar - Self.j2000TT) < 1.0)
        #expect(abs(Self.separation(.saturn, .pluto, phi, jdTT: tStar)) < 1e-7)
    }

    @Test func returnsNilWhenNoAspectInTinyWindow() {
        let result = AstroCalculator.exactAspectJulianDayTT(
            of: .sun, and: .moon, aspectAngleDegrees: 90,
            nearJulianDayTT: Self.j2000TT, searchWindowDays: 0.001
        )
        #expect(result == nil)
    }

    @Test func picksNearestAmongRecurringConjunctions() throws {
        let near0 = try #require(
            AstroCalculator.exactAspectJulianDayTT(
                of: .sun, and: .moon, aspectAngleDegrees: 0, nearJulianDayTT: Self.j2000TT
            )
        )
        let shifted = Self.j2000TT + 29.5
        let nearShift = try #require(
            AstroCalculator.exactAspectJulianDayTT(
                of: .sun, and: .moon, aspectAngleDegrees: 0, nearJulianDayTT: shifted
            )
        )
        #expect(abs(near0 - nearShift) > 20.0)
        #expect(abs(Self.separation(.sun, .moon, 0, jdTT: nearShift)) < 1e-7)
        #expect(abs(nearShift - shifted) <= abs(near0 - shifted))
    }

    @Test func utPathInversionIsSelfConsistent() throws {
        let nearUT = Self.j2000TT
        let tStarUT = try #require(
            AstroCalculator.exactAspectJulianDayUT(
                of: .sun, and: .moon, aspectAngleDegrees: 0, nearJulianDayUT: nearUT
            )
        )
        let la = AstroCalculator.eclipticLongitude(of: .sun, julianDayUT: tStarUT)
        let lb = AstroCalculator.eclipticLongitude(of: .moon, julianDayUT: tStarUT)
        #expect(
            abs(AstroCalculator.aspectSeparation(
                longitudeA: la, longitudeB: lb, aspectAngleDegrees: 0
            )) < 1e-6
        )
        let dt = AstroCalculator.deltaTSeconds(julianDayUT: tStarUT) / 86400.0
        let tStarTT = try #require(
            AstroCalculator.exactAspectJulianDayTT(
                of: .sun, and: .moon, aspectAngleDegrees: 0, nearJulianDayTT: tStarUT + dt
            )
        )
        #expect(abs((tStarTT - tStarUT) - dt) < 1e-5)
    }
}
