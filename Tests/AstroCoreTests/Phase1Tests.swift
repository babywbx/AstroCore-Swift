import Testing

@testable import AstroCore

// Phase 1: Time Foundation Tests

@Suite("Julian Day Tests")
struct JulianDayTests {
    // Meeus Example 7.a: 1957 Oct 4.81 → JD 2436116.31
    @Test func meeusExample7a() {
        let jd = JulianDay.julianDay(year: 1957, month: 10, dayFraction: 4.81)
        #expect(abs(jd - 2436116.31) < 0.000001)
    }

    // J2000.0: 2000-01-01 12:00 UTC → JD 2451545.0
    @Test func j2000() {
        let jd = JulianDay.julianDay(year: 2000, month: 1, dayFraction: 1.5)
        #expect(abs(jd - 2451545.0) < 0.000001)
    }

    // Meeus Example 7.b: 333 Jan 27.5 → JD 1842713.0
    // This is Julian calendar, but our implementation is Gregorian only.
    // Gregorian: 333-01-27.5 with Gregorian B correction
    // Let's use a known Gregorian date instead.
    // 1999-01-01 0:00 UTC → JD 2451179.5
    @Test func jan1_1999() {
        let jd = JulianDay.julianDay(year: 1999, month: 1, dayFraction: 1.0)
        #expect(abs(jd - 2451179.5) < 0.000001)
    }

    // 1987 April 10 0h → JD 2446895.5 (Meeus Ex 22.a date)
    @Test func meeusEx22aDate() {
        let jd = JulianDay.julianDay(year: 1987, month: 4, dayFraction: 10.0)
        #expect(abs(jd - 2446895.5) < 0.000001)
    }

    @Test func julianCenturiesFromJ2000() {
        let jd = 2451545.0 // J2000.0
        let t = JulianDay.julianCenturiesUT(jd: jd)
        #expect(abs(t) < 1e-10)
    }

    @Test func civilMomentConversion() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneIdentifier: "UTC"
        )
        let jd = JulianDay.julianDay(for: moment)
        #expect(abs(jd - 2451545.0) < 0.000001)
    }
}

@Suite("DeltaT Tests")
struct DeltaTTests {
    // Known approximate ΔT values
    @Test func year2000() {
        let dt = DeltaT.deltaT(decimalYear: 2000.0)
        // ΔT around 2000 ≈ 63.83s
        #expect(abs(dt - 63.83) < 1.0)
    }

    @Test func year1900() {
        let dt = DeltaT.deltaT(decimalYear: 1900.0)
        // ΔT around 1900 ≈ -2.79s
        #expect(abs(dt - (-2.79)) < 1.0)
    }

    @Test func year1950() {
        let dt = DeltaT.deltaT(decimalYear: 1950.0)
        // ΔT around 1950 ≈ 29.07s
        #expect(abs(dt - 29.07) < 1.0)
    }

    @Test func year2020() {
        let dt = DeltaT.deltaT(decimalYear: 2020.0)
        // Espenak & Meeus formula predicts ~71.6s for 2020
        // (actual observed was ~69.4s, but we follow the published formula)
        #expect(abs(dt - 71.6) < 1.0)
    }

    @Test func year2050Boundary() {
        let dt = DeltaT.deltaT(decimalYear: 2050.0)
        // At boundary: both formulas should give similar values
        #expect(dt > 80.0 && dt < 110.0)
    }

    @Test func year2100() {
        let dt = DeltaT.deltaT(decimalYear: 2100.0)
        // Espenak & Meeus 2050-2150 formula: u=(2100-1820)/100=2.8
        // -20 + 32*2.8^2 - 0.5628*(2150-2100) = -20 + 250.88 - 28.14 = 202.74
        #expect(abs(dt - 202.74) < 0.5)
    }
}

@Suite("CivilMoment Tests")
struct CivilMomentTests {
    @Test func validCreation() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 15,
            hour: 12, minute: 30, second: 0,
            timeZoneIdentifier: "America/New_York"
        )
        #expect(moment.year == 2000)
        #expect(moment.month == 6)
    }

    @Test func invalidYear() {
        #expect(throws: AstroError.self) {
            try CivilMoment(
                year: 1700, month: 1, day: 1,
                hour: 0, minute: 0,
                timeZoneIdentifier: "UTC"
            )
        }
    }

    @Test func leapYear() throws {
        // Feb 29 in leap year should work
        _ = try CivilMoment(
            year: 2000, month: 2, day: 29,
            hour: 0, minute: 0,
            timeZoneIdentifier: "UTC"
        )
    }

    @Test func notLeapYear2100() {
        // 2100 is NOT a leap year (divisible by 100 but not 400)
        #expect(throws: AstroError.self) {
            try CivilMoment(
                year: 2100, month: 2, day: 29,
                hour: 0, minute: 0,
                timeZoneIdentifier: "UTC"
            )
        }
    }

    @Test func invalidTimezone() {
        #expect(throws: AstroError.self) {
            try CivilMoment(
                year: 2000, month: 1, day: 1,
                hour: 0, minute: 0,
                timeZoneIdentifier: "Invalid/Zone"
            )
        }
    }

    @Test func decimalYear() throws {
        let moment = try CivilMoment(
            year: 2000, month: 7, day: 1,
            hour: 0, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        // y = 2000 + (7 - 0.5)/12 = 2000.5417
        #expect(abs(moment.decimalYear - 2000.5417) < 0.01)
    }

    @Test func utcConversion() throws {
        // 2000-01-01 19:00 EST = 2000-01-02 00:00 UTC
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1,
            hour: 19, minute: 0, second: 0,
            timeZoneIdentifier: "America/New_York"
        )
        let utc = try moment.toUTCComponents()
        #expect(utc.year == 2000)
        #expect(utc.month == 1)
        #expect(utc.day == 2)
        #expect(utc.hour == 0)
    }
}

@Suite("GeoCoordinate Tests")
struct GeoCoordinateTests {
    @Test func validCoordinate() throws {
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        #expect(coord.latitude == 40.7128)
        #expect(coord.longitude == -74.0060)
    }

    @Test func invalidLatitude() {
        #expect(throws: AstroError.self) {
            try GeoCoordinate(latitude: 91.0, longitude: 0.0)
        }
    }

    @Test func invalidLongitude() {
        #expect(throws: AstroError.self) {
            try GeoCoordinate(latitude: 0.0, longitude: 181.0)
        }
    }

    @Test func extremeLatitude() throws {
        let coord = try GeoCoordinate(latitude: 86.0, longitude: 0.0)
        #expect(throws: AstroError.self) {
            try coord.validateForAscendant()
        }
    }

    @Test func polarValid() throws {
        // Exactly 85° should be fine
        let coord = try GeoCoordinate(latitude: 85.0, longitude: 0.0)
        try coord.validateForAscendant()
    }
}

@Suite("SiderealTime Tests")
struct SiderealTimeTests {
    // Meeus Example 12.a: 1987-04-10 0h UT
    // JD = 2446895.5
    // GMST = 13h 10m 46.3668s = 197.69319° (approximately)
    @Test func meeusExample12a() {
        let jd = 2446895.5 // 1987 April 10, 0h UT
        let gmst = SiderealTime.gmst(jdUT: jd)
        // Meeus: θ₀ = 197°41′42.44″ = 197.69512°
        #expect(abs(gmst - 197.6951) < 0.01)
    }
}

@Suite("AngleMath Tests")
struct AngleMathTests {
    @Test func normalizePositive() {
        #expect(AngleMath.normalized(degrees: 370.0) == 10.0)
    }

    @Test func normalizeNegative() {
        #expect(AngleMath.normalized(degrees: -10.0) == 350.0)
    }

    @Test func normalizeZero() {
        #expect(AngleMath.normalized(degrees: 0.0) == 0.0)
    }

    @Test func normalize360() {
        #expect(AngleMath.normalized(degrees: 360.0) == 0.0)
    }

    @Test func normalize720() {
        #expect(AngleMath.normalized(degrees: 720.0) == 0.0)
    }
}

@Suite("ZodiacMapper Tests")
struct ZodiacMapperTests {
    @Test func ariesStart() {
        let sign = ZodiacMapper.sign(forLongitude: 0.0)
        #expect(sign == .aries)
    }

    @Test func taurus() {
        let sign = ZodiacMapper.sign(forLongitude: 45.0)
        #expect(sign == .taurus)
    }

    @Test func pisces() {
        let sign = ZodiacMapper.sign(forLongitude: 350.0)
        #expect(sign == .pisces)
    }

    @Test func boundary() {
        #expect(ZodiacMapper.isBoundaryCase(longitude: 29.8))
        #expect(ZodiacMapper.isBoundaryCase(longitude: 30.3))
        #expect(!ZodiacMapper.isBoundaryCase(longitude: 15.0))
    }

    @Test func degreeInSign() {
        let deg = ZodiacMapper.degreeInSign(longitude: 45.5)
        #expect(abs(deg - 15.5) < 0.001)
    }
}
