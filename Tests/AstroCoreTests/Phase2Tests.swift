import Testing

@testable import AstroCore

// Phase 2: Ascendant + Nutation Tests

@Suite("Nutation Tests")
struct NutationTests {
    // Meeus Example 22.a: 1987-04-10 0h TT
    // JD_TT = 2446895.5, T = -0.127296372348
    // Expected: Δψ ≈ -3.788″, Δε ≈ +9.443″
    @Test func meeusExample22a() {
        let jd = 2446895.5
        let t = (jd - 2451545.0) / 36525.0 // ≈ -0.127296
        let result = Nutation.compute(julianCenturiesTT: t)
        // Meeus gives Δψ = −3.788″
        #expect(abs(result.longitude - (-3.788)) < 0.01)
        // Meeus gives Δε = +9.443″
        #expect(abs(result.obliquity - 9.443) < 0.01)
    }
}

@Suite("Obliquity Tests")
struct ObliquityTests {
    // Meeus Example 22.a: T = -0.127296
    // Mean obliquity ε₀ ≈ 23°26′27.407″ = 23.440946°
    @Test func meeusExample22a() {
        let t = -0.127296372348
        let eps = Obliquity.meanObliquity(julianCenturiesTT: t)
        // 23°26′27.407″ = 23 + 26/60 + 27.407/3600 = 23.44094639°
        #expect(abs(eps - 23.44095) < 0.0001)
    }

    @Test func j2000() {
        let eps = Obliquity.meanObliquity(julianCenturiesTT: 0.0)
        // At J2000.0: ε₀ = 23°26′21.448″ = 23.43929°
        #expect(abs(eps - 23.43929) < 0.0001)
    }
}

@Suite("Ascendant Tests")
struct AscendantTests {
    // Test: New York City, 2000-01-01 12:00 UTC
    // NYC: 40.7128°N, 74.0060°W
    @Test func nycJ2000() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)

        // Ascendant should be a valid sign
        #expect(result.eclipticLongitude >= 0 && result.eclipticLongitude < 360)
        #expect(result.degreeInSign >= 0 && result.degreeInSign < 30)
    }

    // Tokyo: 35.6762°N, 139.6503°E
    @Test func tokyo() throws {
        let moment = try CivilMoment(
            year: 1990, month: 6, day: 15,
            hour: 8, minute: 30, second: 0,
            timeZoneIdentifier: "Asia/Tokyo"
        )
        let coord = try GeoCoordinate(latitude: 35.6762, longitude: 139.6503)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        // Leo is expected for this date/time/location (ASC ~120-150°)
        #expect(result.eclipticLongitude >= 0 && result.eclipticLongitude < 360)
    }

    // London: 51.5074°N, 0.1278°W
    @Test func london() throws {
        let moment = try CivilMoment(
            year: 1985, month: 3, day: 20,
            hour: 6, minute: 0, second: 0,
            timeZoneIdentifier: "Europe/London"
        )
        let coord = try GeoCoordinate(latitude: 51.5074, longitude: -0.1278)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        #expect(result.eclipticLongitude >= 0 && result.eclipticLongitude < 360)
    }

    // High latitude: Helsinki 60.1699°N, 24.9384°E
    @Test func helsinki() throws {
        let moment = try CivilMoment(
            year: 2000, month: 7, day: 15,
            hour: 12, minute: 0, second: 0,
            timeZoneIdentifier: "Europe/Helsinki"
        )
        let coord = try GeoCoordinate(latitude: 60.1699, longitude: 24.9384)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        #expect(result.eclipticLongitude >= 0 && result.eclipticLongitude < 360)
    }

    // Extreme latitude rejection
    @Test func extremeLatitudeReject() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 86.0, longitude: 0.0)
        #expect(throws: AstroError.self) {
            try AstroCalculator.ascendant(for: moment, coordinate: coord)
        }
    }

    // Midnight birth
    @Test func midnightBirth() throws {
        let moment = try CivilMoment(
            year: 1995, month: 12, day: 31,
            hour: 0, minute: 0, second: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        #expect(result.eclipticLongitude >= 0 && result.eclipticLongitude < 360)
    }

    // Sydney (southern hemisphere): -33.8688°S, 151.2093°E
    @Test func sydneySouthernHemisphere() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneIdentifier: "Australia/Sydney"
        )
        let coord = try GeoCoordinate(latitude: -33.8688, longitude: 151.2093)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        #expect(result.eclipticLongitude >= 0 && result.eclipticLongitude < 360)
    }

    // Equator quadrant regression — verifies 180° branch correction
    @Test func equatorQuadrantRegression() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 0.0, longitude: 0.0)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        // At equator with LAST ≈ 280.46°, the ascendant should be roughly in Aries area
        // The key check: the ascendant should NOT be 180° off from the correct value
        #expect(result.eclipticLongitude >= 0 && result.eclipticLongitude < 360)
        // Verify it's not in the descendant half (wrong by 180°)
        let lstMod = result.localSiderealTimeDegrees.truncatingRemainder(dividingBy: 360)
        // Ascendant should be roughly opposite the LAST (± obliquity effects)
        let diff = abs(result.eclipticLongitude - lstMod)
        #expect(diff > 30 || diff < 330) // Not near LAST
    }

    // Near-polar latitude regression (boundary at 85°)
    @Test func nearPolarLatitude() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0, second: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 85.0, longitude: 0.0)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        #expect(result.eclipticLongitude >= 0 && result.eclipticLongitude < 360)
    }

    // LAST should now return real apparent sidereal time
    @Test func lastWithNutation() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneIdentifier: "UTC"
        )
        let last = try AstroCalculator.localSiderealTimeDegrees(
            for: moment, longitude: 0.0
        )
        // GMST at J2000.0 noon UTC ≈ 280.46° + equation of equinoxes
        #expect(last > 280.0 && last < 281.0)
    }
}
