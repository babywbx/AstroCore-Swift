@testable import AstroCore
import Testing

@Suite("Horizontal Coordinate")
struct HorizontalCoordinateTests {
    private func observer() throws -> GeoCoordinate {
        try GeoCoordinate(latitude: 51.4779, longitude: -0.0015, elevation: 45.0)
    }

    @Test func altitudeAndAzimuthInRange() throws {
        let moment = try CivilMoment(
            year: 2024, month: 6, day: 21, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        let obs = try observer()
        for body in CelestialBody.allCases {
            let h = AstroCalculator.horizontal(of: body, at: moment, observer: obs)
            #expect((-90.0...90.0).contains(h.altitude))
            #expect((0.0..<360.0).contains(h.azimuth))
        }
    }

    @Test func computedPointsHaveFiniteHorizontalWithoutParallax() throws {
        let moment = try CivilMoment(
            year: 2024, month: 6, day: 21, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        let obs = try observer()
        for point in [CelestialBody.meanNode, .trueNode, .lilith, .trueLilith] {
            let h = AstroCalculator.horizontal(of: point, at: moment, observer: obs)
            #expect(h.altitude.isFinite && h.azimuth.isFinite)
        }
    }

    @Test func sunIsHighNearLocalNoonAndDownAtNight() throws {
        let obs = try GeoCoordinate(latitude: 0.0, longitude: 0.0)
        let noon = try CivilMoment(
            year: 2024, month: 3, day: 20, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        #expect(AstroCalculator.horizontal(of: .sun, at: noon, observer: obs).altitude > 45.0)
        let midnight = try CivilMoment(
            year: 2024, month: 3, day: 20, hour: 0, minute: 0, timeZoneIdentifier: "UTC"
        )
        #expect(AstroCalculator.horizontal(of: .sun, at: midnight, observer: obs).altitude < 0.0)
    }

    /// Anchor against a local reference ephemeris. MEASURED, NOT FABRICATED.
    /// Topocentric geometric (airless) alt/az; observer = Greenwich (51.4779, -0.0015, 45 m), 2024-06-21 12:00:00 UTC.
    /// tolerance = 10 arcsec, from measured engine-vs-reference agreement (largest delta ~1.3" on moon az).
    @Test func horizontalMatchesIndependentAnchors() throws {
        let moment = try CivilMoment(year: 2024, month: 6, day: 21, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let obs = try observer()
        let tol = 10.0 / 3600.0
        let sun = AstroCalculator.horizontal(of: .sun, at: moment, observer: obs)
        #expect(abs(sun.altitude - 61.95536) < tol)
        AstroCoreTestSupport.expectCircularlyEqual(sun.azimuth, 179.05960, tolerance: tol, "sun az")
        let moon = AstroCalculator.horizontal(of: .moon, at: moment, observer: obs)
        #expect(abs(moon.altitude + 66.32013) < tol)
        AstroCoreTestSupport.expectCircularlyEqual(moon.azimuth, 15.83647, tolerance: tol, "moon az")
    }

    @Test func refractionRaisesLowAltitudeAndVanishesHigh() {
        // Standard refraction (Bennett): ~34′ at the horizon, ~0 at the zenith.
        let atHorizon = Refraction.apparentAltitude(geometricAltitudeDegrees: 0.0)
        #expect(atHorizon > 0.4 && atHorizon < 0.7) // ~34′ ≈ 0.57°
        let high = Refraction.apparentAltitude(geometricAltitudeDegrees: 80.0)
        #expect(abs(high - 80.0) < 0.01) // negligible near zenith
        #expect(Refraction.apparentAltitude(geometricAltitudeDegrees: 45.0) > 45.0)
    }

    @Test func refractionIsFiniteAndSafeBelowHorizon() {
        // The Bennett pole at h=-4.4 must not produce NaN; below ~-1° we return geometric unchanged.
        for h in [-1.0001, -4.4, -5.0, -18.0, -90.0] {
            let apparent = Refraction.apparentAltitude(geometricAltitudeDegrees: h)
            #expect(apparent.isFinite)
            #expect(apparent == h) // unchanged below the horizon threshold
        }
        // Just above the threshold stays finite and refraction is positive (raises altitude).
        let nearHorizon = Refraction.apparentAltitude(geometricAltitudeDegrees: 0.0)
        #expect(nearHorizon.isFinite && nearHorizon > 0.0)
    }
}
