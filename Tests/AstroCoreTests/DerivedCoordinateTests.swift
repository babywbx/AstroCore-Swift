@testable import AstroCore
import Testing

@Suite("Derived Coordinates")
struct DerivedCoordinateTests {
    private func j2000() throws -> CivilMoment {
        try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
    }

    // Wiring: equatorial(of:at:) must rotate the SAME apparent (λ, β) by the SAME true ε.
    @Test func equatorialMatchesRotationOfApparentEcliptic() throws {
        let moment = try j2000()
        for body in CelestialBody.allCases {
            let position = AstroCalculator.planetPosition(body, for: moment)
            let expected = EquatorialCoordinate.from(
                eclipticLongitudeDegrees: position.longitude,
                latitudeDegrees: position.latitude,
                trueObliquityDegrees: moment.trueObliquity
            )
            #expect(AstroCalculator.equatorial(of: body, at: moment) == expected)
        }
    }

    /// Range sanity: declination within [-90,90], RA normalized to [0,360).
    @Test func equatorialStaysInRange() throws {
        let moment = try j2000()
        for body in CelestialBody.allCases {
            let eq = AstroCalculator.equatorial(of: body, at: moment)
            #expect((0.0..<360.0).contains(eq.rightAscension))
            #expect((-90.0...90.0).contains(eq.declination))
        }
    }

    // TODO(a4a): fill RA/Dec from local reference capture (controller will drive). Keep commented until then.
    // Independent anchors captured from local reference tooling (apparent geocentric RA/Dec of date).
    // VALUES ARE MEASURED, NOT FABRICATED. Tolerance = 2 arcseconds.
    // @Test func equatorialMatchesIndependentAnchors() throws {
    //     let moment = try j2000()
    //     let twoArcsec = 2.0 / 3600.0
    //     let anchors: [(CelestialBody, Double, Double)] = [
    //         (.sun, MEASURED_SUN_RA, MEASURED_SUN_DEC),
    //         (.moon, MEASURED_MOON_RA, MEASURED_MOON_DEC),
    //         (.mars, MEASURED_MARS_RA, MEASURED_MARS_DEC)
    //     ]
    //     for (body, ra, dec) in anchors {
    //         let eq = AstroCalculator.equatorial(of: body, at: moment)
    //         AstroCoreTestSupport.expectCircularlyEqual(eq.rightAscension, ra, tolerance: twoArcsec, "\(body) ra")
    //         #expect(abs(eq.declination - dec) < twoArcsec)
    //     }
    // }
}
