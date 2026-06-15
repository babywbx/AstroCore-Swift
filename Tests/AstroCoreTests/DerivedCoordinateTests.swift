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

    /// Independent anchors captured from local reference tooling (apparent geocentric RA/Dec of date).
    /// VALUES ARE MEASURED, NOT FABRICATED. Tolerance = 2 arcseconds.
    @Test func equatorialMatchesIndependentAnchors() throws {
        let moment = try j2000()
        let twoArcsec = 2.0 / 3600.0
        let anchors: [(CelestialBody, Double, Double)] = [
            (.sun, 281.278380, -23.032430),
            (.moon, 222.452200, -10.900650),
            (.mars, 330.516800, -13.182480)
        ]
        for (body, ra, dec) in anchors {
            let eq = AstroCalculator.equatorial(of: body, at: moment)
            AstroCoreTestSupport.expectCircularlyEqual(eq.rightAscension, ra, tolerance: twoArcsec, "\(body) ra")
            #expect(abs(eq.declination - dec) < twoArcsec)
        }
    }

    private let heliocentricRadiusRanges: [(CelestialBody, ClosedRange<Double>)] = [
        (.mercury, 0.30...0.48), (.venus, 0.71...0.74), (.mars, 1.36...1.68),
        (.jupiter, 4.9...5.5), (.saturn, 8.9...10.2), (.uranus, 18.2...20.2),
        (.neptune, 29.7...30.5), (.pluto, 29.6...49.4)
    ]

    @Test func heliocentricPlanetsAreInRange() throws {
        let moment = try j2000()
        for (body, range) in heliocentricRadiusRanges {
            let helio = try #require(AstroCalculator.heliocentric(of: body, at: moment))
            #expect((0.0..<360.0).contains(helio.longitude))
            #expect((-90.0...90.0).contains(helio.latitude))
            #expect(range.contains(helio.distance))
        }
    }

    @Test func heliocentricIsNilForNonPlanets() throws {
        let moment = try j2000()
        for body in [CelestialBody.sun, .moon, .meanNode, .trueNode, .lilith, .trueLilith] {
            #expect(AstroCalculator.heliocentric(of: body, at: moment) == nil)
        }
    }

    /// MEASURED, NOT FABRICATED.
    @Test func heliocentricMatchesIndependentAnchor() throws {
        let moment = try j2000()
        let helio = try #require(AstroCalculator.heliocentric(of: .jupiter, at: moment))
        AstroCoreTestSupport.expectCircularlyEqual(helio.longitude, 36.294594, tolerance: 2.0 / 3600.0, "jup helio lon")
        #expect(abs(helio.latitude - -1.174588) < 2.0 / 3600.0)
        #expect(abs(helio.distance - 4.96538103) < 0.00001)
    }
}
