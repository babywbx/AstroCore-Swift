@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

@Suite("Aspect Baselines")
struct AspectBaselineTests {
    private static let mainBodies: [CelestialBody] =
        [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto]

    private static var enabled: Bool {
        ProcessInfo.processInfo.environment["ASTROCORE_ENABLE_BASELINE_VERIFICATION"] == "1"
    }

    @Test func exactMomentLandsOnRealAspectPerReference() throws {
        guard Self.enabled else { return }
        let seed = try AstroCalculator.julianDayUT(
            for: CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        )
        // Sun-Moon conjunction (phi = 0).
        let tStarUT = try #require(
            AstroCalculator.exactAspectJulianDayUT(
                of: .sun, and: .moon, aspectAngleDegrees: 0, nearJulianDayUT: seed
            )
        )
        let reference = try AstrologyTestSupport.referenceBodyLongitudes(
            julianDaysUT: [tStarUT], bodies: [.sun, .moon]
        )
        let sun = try #require(reference.first?[.sun])
        let moon = try #require(reference.first?[.moon])
        let separation = abs(AstroCalculator.aspectSeparation(
            longitudeA: sun, longitudeB: moon, aspectAngleDegrees: 0
        ))
        #expect(separation < 1e-2, "reference separation at t* = \(separation)°")
    }

    @Test func gridOrbsAgreeWithReferenceLongitudes() throws {
        guard Self.enabled else { return }
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30, timeZoneIdentifier: "America/New_York"
        )
        let jdUT = AstroCalculator.julianDayUT(for: moment)
        let grid = try AstrologyCalculator.aspects(
            for: moment, bodies: Set(Self.mainBodies), aspectKinds: Set(AspectKind.allCases)
        )
        let reference = try AstrologyTestSupport.referenceBodyLongitudes(
            julianDaysUT: [jdUT], bodies: Self.mainBodies
        )
        let longitudes = try #require(reference.first)
        for aspect in grid.aspects {
            let a = try #require(longitudes[aspect.bodyA])
            let b = try #require(longitudes[aspect.bodyB])
            let referenceDeviation = AstroCalculator.aspectSeparation(
                longitudeA: a, longitudeB: b, aspectAngleDegrees: aspect.kind.angleDegrees
            )
            #expect(
                abs(aspect.deviation - referenceDeviation) < 1e-2,
                "\(aspect.bodyA)-\(aspect.bodyB) \(aspect.kind.displayName): mine \(aspect.deviation) vs ref \(referenceDeviation)"
            )
        }
    }
}
