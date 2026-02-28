import Testing

@testable import AstroCore

// Phase 4: Reference Data Validation Tests
// Validates computed positions against known ephemeris values.
// All times are UTC wall clock (not TT). Tolerances reflect VSOP87D/ELP2000 precision.

@Suite("Sun Position Validation")
struct SunValidationTests {
    // 2000-01-01 12:00 UTC: Sun geocentric apparent lon ≈ 280.37°
    @Test func sun_2000_01_01() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.sunPosition(for: moment)
        #expect(abs(pos.longitude - 280.369) < 0.05)
        #expect(pos.sign == .capricorn)
    }

    // 2000-06-21 12:00 UTC: Sun near summer solstice ≈ 90.41°
    @Test func sun_2000_06_21() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.sunPosition(for: moment)
        #expect(abs(pos.longitude - 90.406) < 0.05)
        #expect(pos.sign == .cancer)
    }

    // 1990-03-20 12:00 UTC: Near vernal equinox, Sun ≈ 359.61°
    @Test func sun_1990_03_20() throws {
        let moment = try CivilMoment(
            year: 1990, month: 3, day: 20, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.sunPosition(for: moment)
        #expect(abs(pos.longitude - 359.614) < 0.05)
        #expect(pos.sign == .pisces)
    }

    // 2024-12-21 12:00 UTC: Winter solstice, Sun ≈ 270.11°
    @Test func sun_2024_12_21() throws {
        let moment = try CivilMoment(
            year: 2024, month: 12, day: 21, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.sunPosition(for: moment)
        #expect(abs(pos.longitude - 270.113) < 0.05)
        #expect(pos.sign == .capricorn)
    }
}

@Suite("Moon Position Validation")
struct MoonValidationTests {
    // 2000-01-01 12:00 UTC: Moon ≈ 223.32° (Scorpio)
    @Test func moon_2000_01_01() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.moonPosition(for: moment)
        // ELP2000 truncated series; tolerance ≤ 0.5°
        #expect(abs(pos.longitude - 223.32) < 0.5)
        #expect(pos.sign == .scorpio)
        #expect(abs(pos.latitude - 5.17) < 0.5)
    }

    // Moon moves ~13.2°/day — verify rate is in [11°, 15°]
    @Test func moonDailyMotion() throws {
        let m1 = try CivilMoment(
            year: 2000, month: 6, day: 1, hour: 0, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let m2 = try CivilMoment(
            year: 2000, month: 6, day: 2, hour: 0, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let p1 = try AstroCalculator.moonPosition(for: m1)
        let p2 = try AstroCalculator.moonPosition(for: m2)
        var diff = p2.longitude - p1.longitude
        if diff < 0 { diff += 360.0 }
        // Computed: ~14.82°/day, within normal range [11°, 15°]
        #expect(diff > 11.0 && diff < 15.0)
    }
}

@Suite("Planet Position Validation")
struct PlanetValidationTests {
    // All at 2000-01-01 12:00 UTC, geocentric apparent ecliptic longitude

    // Mercury ≈ 271.90°
    @Test func mercury_2000_01_01() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.planetPosition(.mercury, for: moment)
        #expect(abs(pos.longitude - 271.895) < 0.15)
        #expect(pos.sign == .capricorn)
    }

    // Venus ≈ 241.57°
    @Test func venus_2000_01_01() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.planetPosition(.venus, for: moment)
        #expect(abs(pos.longitude - 241.570) < 0.15)
        #expect(pos.sign == .sagittarius)
    }

    // Mars ≈ 327.97°
    @Test func mars_2000_01_01() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.planetPosition(.mars, for: moment)
        #expect(abs(pos.longitude - 327.967) < 0.15)
        #expect(pos.sign == .aquarius)
    }

    // Jupiter ≈ 25.25°
    @Test func jupiter_2000_01_01() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.planetPosition(.jupiter, for: moment)
        #expect(abs(pos.longitude - 25.252) < 0.15)
        #expect(pos.sign == .aries)
    }

    // Saturn ≈ 40.39°
    @Test func saturn_2000_01_01() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.planetPosition(.saturn, for: moment)
        #expect(abs(pos.longitude - 40.393) < 0.15)
        #expect(pos.sign == .taurus)
    }
}

@Suite("Ascendant Reference Tests")
struct AscendantReferenceTests {
    // NYC, 1990-08-15 14:30 EDT → ASC ≈ 240.93° (Sagittarius 0°56')
    @Test func nyc_1990_08_15() throws {
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30,
            timeZoneIdentifier: "America/New_York"
        )
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        #expect(abs(result.eclipticLongitude - 240.93) < 0.5)
        #expect(result.sign == .sagittarius)
    }

    // London, 2000-01-01 00:00 GMT → ASC ≈ 186.94° (Libra 6°56')
    @Test func london_2000_01_01() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 0, minute: 0,
            timeZoneIdentifier: "Europe/London"
        )
        let coord = try GeoCoordinate(latitude: 51.5074, longitude: -0.1278)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        #expect(abs(result.eclipticLongitude - 186.94) < 0.5)
        #expect(result.sign == .libra)
    }

    // Tokyo, 1985-06-15 08:00 JST → ASC ≈ 128.91° (Leo 8°55')
    @Test func tokyo_1985_06_15() throws {
        let moment = try CivilMoment(
            year: 1985, month: 6, day: 15, hour: 8, minute: 0,
            timeZoneIdentifier: "Asia/Tokyo"
        )
        let coord = try GeoCoordinate(latitude: 35.6762, longitude: 139.6503)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        #expect(abs(result.eclipticLongitude - 128.91) < 0.5)
        #expect(result.sign == .leo)
    }

    // Sydney, 1995-12-25 12:00 AEDT — southern hemisphere smoke test
    @Test func sydney_1995_12_25() throws {
        let moment = try CivilMoment(
            year: 1995, month: 12, day: 25, hour: 12, minute: 0,
            timeZoneIdentifier: "Australia/Sydney"
        )
        let coord = try GeoCoordinate(latitude: -33.8688, longitude: 151.2093)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        #expect(result.eclipticLongitude >= 0 && result.eclipticLongitude < 360)
        #expect(result.sign != nil)
    }

    // Berlin, 1975-09-20 15:00 CET → ASC ≈ 277.54° (Capricorn 7°33')
    @Test func berlin_1975_09_20() throws {
        let moment = try CivilMoment(
            year: 1975, month: 9, day: 20, hour: 15, minute: 0,
            timeZoneIdentifier: "Europe/Berlin"
        )
        let coord = try GeoCoordinate(latitude: 52.5200, longitude: 13.4050)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        #expect(abs(result.eclipticLongitude - 277.54) < 0.5)
        #expect(result.sign == .capricorn)
    }

    // Mumbai, 2010-04-10 06:00 IST — dawn, ASC near Aries
    @Test func mumbai_2010_04_10() throws {
        let moment = try CivilMoment(
            year: 2010, month: 4, day: 10, hour: 6, minute: 0,
            timeZoneIdentifier: "Asia/Kolkata"
        )
        let coord = try GeoCoordinate(latitude: 19.0760, longitude: 72.8777)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        // At dawn in mid-April, ASC should be near Aries/Taurus
        #expect(result.sign == .aries || result.sign == .taurus)
    }

    // Los Angeles, 2020-01-01 00:00 PST — midnight, ASC in Virgo/Libra
    @Test func la_2020_01_01() throws {
        let moment = try CivilMoment(
            year: 2020, month: 1, day: 1, hour: 0, minute: 0,
            timeZoneIdentifier: "America/Los_Angeles"
        )
        let coord = try GeoCoordinate(latitude: 34.0522, longitude: -118.2437)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        #expect(result.sign == .virgo || result.sign == .libra)
    }

    // Helsinki high latitude (60.17°N), 2000-06-21 12:00 EEST
    @Test func helsinki_2000_06_21() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21, hour: 12, minute: 0,
            timeZoneIdentifier: "Europe/Helsinki"
        )
        let coord = try GeoCoordinate(latitude: 60.1699, longitude: 24.9384)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        #expect(result.eclipticLongitude >= 0 && result.eclipticLongitude < 360)
    }

    // Near-polar latitude boundary: 84.9° should succeed, 85.1° should throw
    @Test func polarLatitudeBoundary() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let valid = try GeoCoordinate(latitude: 84.9, longitude: 0.0)
        let result = try AstroCalculator.ascendant(for: moment, coordinate: valid)
        #expect(result.eclipticLongitude >= 0 && result.eclipticLongitude < 360)

        let extreme = try GeoCoordinate(latitude: 85.1, longitude: 0.0)
        #expect(throws: AstroError.extremeLatitude) {
            try AstroCalculator.ascendant(for: moment, coordinate: extreme)
        }
    }
}

@Suite("Full Natal Chart Validation")
struct FullChartValidationTests {
    // Einstein birth chart: March 14, 1879, 11:30 local time, Ulm Germany
    // Note: uses Europe/Berlin IANA zone; pre-1970 tzdb history may differ from
    // historical LMT by ~20 min, so we only validate Sun sign + completeness.
    @Test func einsteinBirthChart() throws {
        let moment = try CivilMoment(
            year: 1879, month: 3, day: 14, hour: 11, minute: 30,
            timeZoneIdentifier: "Europe/Berlin"
        )
        let coord = try GeoCoordinate(latitude: 48.4011, longitude: 9.9876)

        let natal = try AstroCalculator.natalPositions(
            for: moment,
            coordinate: coord,
            bodies: [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn],
            includeAscendant: true
        )

        // Sun in Pisces (late Feb / March)
        #expect(natal.bodies[.sun]?.sign == .pisces)
        #expect(natal.bodies.count == 7)
        #expect(natal.ascendant != nil)
    }

    // Equator, prime meridian: 1950-01-01 00:00 UTC
    @Test func equatorChart() throws {
        let moment = try CivilMoment(
            year: 1950, month: 1, day: 1, hour: 0, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 0.0, longitude: 0.0)

        let natal = try AstroCalculator.natalPositions(
            for: moment,
            coordinate: coord,
            bodies: [.sun, .moon],
            includeAscendant: true
        )

        #expect(natal.bodies[.sun]?.sign == .capricorn)
        #expect(natal.ascendant != nil)
    }

    // Missing coordinate for ascendant should throw the specific error
    @Test func missingCoordinateThrows() {
        #expect(throws: AstroError.missingCoordinateForAscendant) {
            let moment = try CivilMoment(
                year: 2000, month: 1, day: 1, hour: 12, minute: 0,
                timeZoneIdentifier: "UTC"
            )
            _ = try AstroCalculator.natalPositions(
                for: moment,
                bodies: [.sun],
                includeAscendant: true
            )
        }
    }

    // Year 1800 boundary — valid range floor
    @Test func year1800() throws {
        let moment = try CivilMoment(
            year: 1800, month: 6, day: 15, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.sunPosition(for: moment)
        #expect(pos.longitude >= 0 && pos.longitude < 360)
        #expect(pos.sign == .gemini || pos.sign == .cancer)
    }

    // Year 2100 boundary — valid range ceiling
    @Test func year2100() throws {
        let moment = try CivilMoment(
            year: 2100, month: 6, day: 15, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.sunPosition(for: moment)
        #expect(pos.longitude >= 0 && pos.longitude < 360)
        #expect(pos.sign == .gemini || pos.sign == .cancer)
    }

    // Out-of-range year should throw
    @Test func outOfRangeYear() {
        #expect(throws: AstroError.unsupportedYearRange(1799)) {
            _ = try CivilMoment(
                year: 1799, month: 1, day: 1, hour: 0, minute: 0,
                timeZoneIdentifier: "UTC"
            )
        }
        #expect(throws: AstroError.unsupportedYearRange(2101)) {
            _ = try CivilMoment(
                year: 2101, month: 1, day: 1, hour: 0, minute: 0,
                timeZoneIdentifier: "UTC"
            )
        }
    }

    // Sign boundary precision: 30.000° should be Taurus, 29.999° should be Aries
    @Test func signBoundaryPrecision() {
        let sign30 = ZodiacMapper.sign(forLongitude: 30.0)
        #expect(sign30 == .taurus)
        let sign29_999 = ZodiacMapper.sign(forLongitude: 29.999)
        #expect(sign29_999 == .aries)
        let sign359_999 = ZodiacMapper.sign(forLongitude: 359.999)
        #expect(sign359_999 == .pisces)
        let sign0 = ZodiacMapper.sign(forLongitude: 0.0)
        #expect(sign0 == .aries)

        // Boundary detection
        #expect(ZodiacMapper.isBoundaryCase(longitude: 29.8))
        #expect(ZodiacMapper.isBoundaryCase(longitude: 30.3))
        #expect(!ZodiacMapper.isBoundaryCase(longitude: 15.0))
    }
}
