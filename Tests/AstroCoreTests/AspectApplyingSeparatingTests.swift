@testable import AstroCore
import Foundation
import Testing

@Suite("Aspect Applying / Separating")
struct AspectApplyingSeparatingTests {
    private static let j2000TT = 2451545.0

    private static func gap(
        _ a: CelestialBody, _ b: CelestialBody, _ phi: Double, jdTT: Double
    ) -> Double {
        let la = AstroCalculator.eclipticLongitude(of: a, julianDayTT: jdTT)
        let lb = AstroCalculator.eclipticLongitude(of: b, julianDayTT: jdTT)
        return abs(AstroCalculator.aspectSeparation(
            longitudeA: la, longitudeB: lb, aspectAngleDegrees: phi
        ))
    }

    private static func closingRate(
        _ a: CelestialBody, _ b: CelestialBody, _ phi: Double, jdTT: Double
    ) -> Double {
        let la = AstroCalculator.eclipticLongitude(of: a, julianDayTT: jdTT)
        let lb = AstroCalculator.eclipticLongitude(of: b, julianDayTT: jdTT)
        let va = AstroCalculator.longitudeSpeed(of: a, julianDayTT: jdTT)
        let vb = AstroCalculator.longitudeSpeed(of: b, julianDayTT: jdTT)
        return AstroCalculator.aspectClosingRate(
            speedA: va, speedB: vb, longitudeA: la, longitudeB: lb, aspectAngleDegrees: phi
        )
    }

    @Test func closingRateSignMatchesGapDerivativeNearConjunction() throws {
        let tStar = try #require(
            AstroCalculator.exactAspectJulianDayTT(
                of: .sun, and: .moon, aspectAngleDegrees: 0, nearJulianDayTT: Self.j2000TT
            )
        )
        let h = 0.01
        for offset in [-2.0, -0.5, 0.5, 2.0] {
            let t = tStar + offset
            let rate = Self.closingRate(.sun, .moon, 0, jdTT: t)
            let dGap = (Self.gap(.sun, .moon, 0, jdTT: t + h) - Self.gap(.sun, .moon, 0, jdTT: t - h)) / (2 * h)
            #expect((rate > 0) == (dGap < 0), "offset \(offset): rate \(rate), dGap \(dGap)")
        }
    }

    @Test func applyingFlipsAcrossExactConjunction() throws {
        let tStar = try #require(
            AstroCalculator.exactAspectJulianDayTT(
                of: .sun, and: .moon, aspectAngleDegrees: 0, nearJulianDayTT: Self.j2000TT
            )
        )
        #expect(Self.closingRate(.sun, .moon, 0, jdTT: tStar - 1.0) > 0)
        #expect(Self.closingRate(.sun, .moon, 0, jdTT: tStar + 1.0) < 0)
    }

    @Test func closingRateSignConsistentForFastSlowPair() throws {
        let tStar = try #require(
            AstroCalculator.exactAspectJulianDayTT(
                of: .moon, and: .saturn, aspectAngleDegrees: 60, nearJulianDayTT: Self.j2000TT
            )
        )
        #expect(Self.gap(.moon, .saturn, 60, jdTT: tStar) < 1e-6)
        let h = 0.01
        for offset in [-0.5, 0.5] {
            let t = tStar + offset
            let rate = Self.closingRate(.moon, .saturn, 60, jdTT: t)
            let dGap = (Self.gap(.moon, .saturn, 60, jdTT: t + h) - Self.gap(.moon, .saturn, 60, jdTT: t - h)) / (2 * h)
            #expect((rate > 0) == (dGap < 0))
        }
    }
}
