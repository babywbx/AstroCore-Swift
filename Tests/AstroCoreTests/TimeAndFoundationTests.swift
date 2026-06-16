@testable import AstroCore
import Foundation
import Testing

struct JulianDayCase: Sendable, CustomStringConvertible {
    let name: String
    let year: Int
    let month: Int
    let dayFraction: Double
    let expected: Double

    var description: String { name }
}

private let julianDayCases: [JulianDayCase] = [
    .init(name: "epoch-2000", year: 2000, month: 1, dayFraction: 1.5, expected: 2451545.0),
    .init(name: "jan-1999", year: 1999, month: 1, dayFraction: 1.0, expected: 2451179.5),
    .init(name: "oct-1957", year: 1957, month: 10, dayFraction: 4.81, expected: 2436116.31),
    .init(name: "apr-1987", year: 1987, month: 4, dayFraction: 10.0, expected: 2446895.5)
]

struct BridgeFixture: Sendable, CustomStringConvertible {
    let name: String
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let second: Int
    let timeZoneIdentifier: String

    var description: String { name }
}

private let bridgeFixtures: [BridgeFixture] = [
    .init(name: "utc-noon", year: 2000, month: 6, day: 21, hour: 12, minute: 0, second: 0, timeZoneIdentifier: "UTC"),
    .init(name: "ny-winter", year: 2000, month: 1, day: 1, hour: 19, minute: 30, second: 15, timeZoneIdentifier: "America/New_York"),
    .init(name: "ny-summer-dst", year: 2021, month: 7, day: 4, hour: 9, minute: 5, second: 0, timeZoneIdentifier: "America/New_York"),
    .init(name: "shanghai-cross-year", year: 2001, month: 1, day: 1, hour: 2, minute: 0, second: 0, timeZoneIdentifier: "Asia/Shanghai"),
    .init(name: "ny-cross-year-back", year: 1999, month: 12, day: 31, hour: 23, minute: 0, second: 0, timeZoneIdentifier: "America/New_York"),
    .init(name: "kolkata-half-hour-leap", year: 2000, month: 2, day: 29, hour: 6, minute: 45, second: 30, timeZoneIdentifier: "Asia/Kolkata"),
    .init(name: "tokyo-evening", year: 2024, month: 11, day: 15, hour: 21, minute: 0, second: 0, timeZoneIdentifier: "Asia/Tokyo")
]

@Suite("Time and Foundation")
struct TimeAndFoundationTests {
    @Test(arguments: julianDayCases)
    func julianDayMatchesKnownInstants(_ testCase: JulianDayCase) {
        let julianDay = JulianDay.julianDay(
            year: testCase.year,
            month: testCase.month,
            dayFraction: testCase.dayFraction
        )
        #expect(abs(julianDay - testCase.expected) < 0.000001)
    }

    @Test(arguments: julianDayCases)
    func calendarDateInvertsJulianDay(_ testCase: JulianDayCase) {
        let date = JulianDay.calendarDate(julianDay: testCase.expected)
        #expect(date.year == testCase.year)
        #expect(date.month == testCase.month)
        let dayFraction = Double(date.day) + date.secondsOfDay / 86400.0
        let roundTrip = JulianDay.julianDay(
            year: date.year,
            month: date.month,
            dayFraction: dayFraction
        )
        #expect(abs(roundTrip - testCase.expected) < 1e-9)
    }

    @Test func calendarDateRecoversCivilFields() {
        let noon = JulianDay.calendarDate(julianDay: 2451545.0)
        #expect(noon.year == 2000 && noon.month == 1 && noon.day == 1)
        #expect(abs(noon.secondsOfDay - 43200.0) < 1e-6)

        let midnight = JulianDay.calendarDate(julianDay: 2451544.5)
        #expect(midnight.year == 2000 && midnight.month == 1 && midnight.day == 1)
        #expect(abs(midnight.secondsOfDay) < 1e-6)

        let endOfDay = JulianDay.calendarDate(julianDay: 2451545.5 - 1.0 / 86400.0)
        #expect(endOfDay.year == 2000 && endOfDay.month == 1 && endOfDay.day == 1)
        #expect(abs(endOfDay.secondsOfDay - 86399.0) < 1e-3)
    }

    @Test(arguments: bridgeFixtures)
    func bridgeRoundTripsJulianDayAndCivilFields(_ fixture: BridgeFixture) throws {
        let original = try CivilMoment(
            year: fixture.year,
            month: fixture.month,
            day: fixture.day,
            hour: fixture.hour,
            minute: fixture.minute,
            second: fixture.second,
            timeZoneIdentifier: fixture.timeZoneIdentifier
        )
        let bridged = try CivilMoment(
            julianDayUT: original.julianDayUT,
            timeZoneIdentifier: fixture.timeZoneIdentifier
        )
        #expect(abs(bridged.julianDayUT - original.julianDayUT) < 1e-9)
        #expect(bridged.year == fixture.year)
        #expect(bridged.month == fixture.month)
        #expect(bridged.day == fixture.day)
        #expect(bridged.hour == fixture.hour)
        #expect(bridged.minute == fixture.minute)
        #expect(bridged.second == fixture.second)
        #expect(bridged.timeZoneIdentifier == fixture.timeZoneIdentifier)
        #expect(bridged == original)
    }

    @Test func julianDayTTAddsDeltaTToUT() throws {
        let moment = try CivilMoment(
            year: 2000,
            month: 1,
            day: 1,
            hour: 12,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )
        #expect(abs(moment.julianDayTT - (moment.julianDayUT + moment.deltaT / 86400.0)) < 1e-12)
        #expect(moment.julianDayTT > moment.julianDayUT)
    }

    @Test func bridgeRejectsOutOfRangeAndInvalidInputs() {
        let jd1700 = JulianDay.julianDay(year: 1700, month: 1, dayFraction: 1.5)
        #expect(throws: AstroError.unsupportedYearRange(1700)) {
            try CivilMoment(julianDayUT: jd1700, timeZoneIdentifier: "UTC")
        }
        #expect(throws: AstroError.invalidTimeZoneIdentifier("Invalid/Zone")) {
            try CivilMoment(julianDayUT: 2451545.0, timeZoneIdentifier: "Invalid/Zone")
        }
        #expect(throws: AstroError.self) {
            try CivilMoment(julianDayUT: .infinity, timeZoneIdentifier: "UTC")
        }
    }

    @Test func julianTimeScalesStayConsistent() {
        let jdUT = JulianDay.j2000
        let deltaT = 63.8285
        let centuries = JulianDay.julianCenturiesTT(jdUT: jdUT, deltaT: deltaT)
        let millennia = JulianDay.julianMillenniaTT(jdUT: jdUT, deltaT: deltaT)
        #expect(abs(millennia * 10.0 - centuries) < 1e-12)
        #expect(centuries > 0.0)
    }

    @Test func angleMathNormalizesRepresentativeAngles() {
        let samples: [(Double, Double)] = [
            (-720.0, 0.0),
            (-360.0, 0.0),
            (-0.0, 0.0),
            (0.0, 0.0),
            (45.0, 45.0),
            (360.0, 0.0),
            (725.5, 5.5)
        ]

        for (input, expected) in samples {
            #expect(AngleMath.normalized(degrees: input) == expected)
        }
    }

    @Test func angleMathAndTrigDegAgreeWithFoundation() {
        let radians = AngleMath.toRadians(180.0)
        #expect(abs(radians - .pi) < 1e-12)
        #expect(abs(AngleMath.toDegrees(.pi / 3.0) - 60.0) < 1e-12)

        let trig = TrigDeg.sincos(30.0)
        #expect(abs(trig.sin - 0.5) < 1e-12)
        #expect(abs(trig.cos - Foundation.sqrt(3.0) / 2.0) < 1e-12)
        #expect(abs(TrigDeg.atan2(1.0, 1.0) - 45.0) < 1e-12)
        #expect(abs(TrigDeg.asin(0.5) - 30.0) < 1e-12)
        #expect(abs(TrigDeg.acos(0.5) - 60.0) < 1e-12)
    }

    @Test func validationCoversLeapYearsAndMonthLengths() {
        #expect(Validation.isLeapYear(2000))
        #expect(!Validation.isLeapYear(1900))
        #expect(Validation.isLeapYear(2024))
        #expect(!Validation.isLeapYear(2025))

        #expect(Validation.daysInMonth(month: 2, year: 2000) == 29)
        #expect(Validation.daysInMonth(month: 2, year: 1900) == 28)
        #expect(Validation.daysInMonth(month: 4, year: 2025) == 30)
        #expect(Validation.daysInMonth(month: 13, year: 2025) == 0)
    }

    @Test func deltaTCoversHistoricModernFutureAndClampedRanges() {
        #expect(abs(DeltaT.deltaT(decimalYear: 1900.0) - -2.79) < 1.0)
        #expect(abs(DeltaT.deltaT(decimalYear: 1950.0) - 29.07) < 1.0)
        #expect(abs(DeltaT.deltaT(decimalYear: 2000.0) - 63.8285) < 0.2)
        #expect(abs(DeltaT.deltaT(decimalYear: 2020.0) - 69.3612) < 0.2)
        #expect(DeltaT.deltaT(decimalYear: 2050.0) > 74.0)
        #expect(DeltaT.deltaT(decimalYear: 2100.0) > 90.0)
        #expect(DeltaT.deltaT(decimalYear: 1700.0) == DeltaT.deltaT(decimalYear: 1800.0))
        #expect(DeltaT.deltaT(decimalYear: 2200.0) == DeltaT.deltaT(decimalYear: 2100.0))
    }

    @Test func civilMomentExposesUTCAndAstronomicalCaches() throws {
        let moment = try CivilMoment(
            year: 2000,
            month: 1,
            day: 1,
            hour: 19,
            minute: 0,
            second: 0,
            timeZoneIdentifier: "America/New_York"
        )

        let utc = try moment.toUTCComponents()
        #expect(utc.year == 2000)
        #expect(utc.month == 1)
        #expect(utc.day == 2)
        #expect(utc.hour == 0)
        #expect(utc.minute == 0)
        #expect(abs(moment.julianDayUT - 2451545.5) < 0.000001)
        #expect(moment.deltaT > 60.0)
        #expect(moment.trueObliquity > 23.0 && moment.trueObliquity < 24.0)
    }

    @Test func civilMomentHandlesDstGapAndFold() {
        #expect(throws: AstroError.invalidCivilMoment(
            detail: "Local time is not representable in America/New_York"
        )) {
            try CivilMoment(
                year: 2000,
                month: 4,
                day: 2,
                hour: 2,
                minute: 30,
                second: 0,
                timeZoneIdentifier: "America/New_York"
            )
        }

        #expect(throws: AstroError.invalidCivilMoment(
            detail: """
            Local time is ambiguous in America/New_York; pass repeatedTimeResolution \
            to choose the first or last occurrence
            """
        )) {
            try CivilMoment(
                year: 2000,
                month: 10,
                day: 29,
                hour: 1,
                minute: 30,
                second: 0,
                timeZoneIdentifier: "America/New_York"
            )
        }
    }

    @Test func civilMomentAllowsExplicitRepeatedTimeResolution() throws {
        let first = try CivilMoment(
            year: 2000,
            month: 10,
            day: 29,
            hour: 1,
            minute: 30,
            second: 0,
            timeZoneIdentifier: "America/New_York",
            repeatedTimeResolution: .firstOccurrence
        )
        let last = try CivilMoment(
            year: 2000,
            month: 10,
            day: 29,
            hour: 1,
            minute: 30,
            second: 0,
            timeZoneIdentifier: "America/New_York",
            repeatedTimeResolution: .lastOccurrence
        )

        let firstUTC = try first.toUTCComponents()
        let lastUTC = try last.toUTCComponents()
        #expect(firstUTC.year == 2000 && lastUTC.year == 2000)
        #expect(firstUTC.month == 10 && lastUTC.month == 10)
        #expect(firstUTC.day == 29 && lastUTC.day == 29)
        #expect(firstUTC.hour == 5)
        #expect(lastUTC.hour == 6)
        #expect(firstUTC.minute == 30 && lastUTC.minute == 30)
        #expect(first != last)
        #expect(first.hashValue != last.hashValue)
    }

    @Test func civilMomentValidatesInputsAndSupportsCodableHashable() throws {
        #expect(throws: AstroError.unsupportedYearRange(1700)) {
            try CivilMoment(
                year: 1700,
                month: 1,
                day: 1,
                hour: 0,
                minute: 0,
                timeZoneIdentifier: "UTC"
            )
        }
        #expect(throws: AstroError.invalidCivilMoment(
            detail: "Month 13 out of range 1...12"
        )) {
            try CivilMoment(
                year: 2000,
                month: 13,
                day: 1,
                hour: 0,
                minute: 0,
                timeZoneIdentifier: "UTC"
            )
        }
        #expect(throws: AstroError.invalidTimeZoneIdentifier("Invalid/Zone")) {
            try CivilMoment(
                year: 2000,
                month: 1,
                day: 1,
                hour: 0,
                minute: 0,
                timeZoneIdentifier: "Invalid/Zone"
            )
        }

        let original = try CivilMoment(
            year: 2000,
            month: 7,
            day: 1,
            hour: 0,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let payload = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CivilMoment.self, from: payload)
        #expect(original == decoded)
        #expect(original.hashValue == decoded.hashValue)
        #expect(abs(original.decimalYear - 2000.4973) < 0.001)

        let ambiguous = try CivilMoment(
            year: 2000,
            month: 10,
            day: 29,
            hour: 1,
            minute: 30,
            second: 0,
            timeZoneIdentifier: "America/New_York",
            repeatedTimeResolution: .lastOccurrence
        )
        let ambiguousPayload = try JSONEncoder().encode(ambiguous)
        let ambiguousDecoded = try JSONDecoder().decode(CivilMoment.self, from: ambiguousPayload)
        #expect(ambiguous == ambiguousDecoded)

        let legacyPayload = Data(
            #"{"year":2000,"month":10,"day":29,"hour":1,"minute":30,"second":0,"timeZoneIdentifier":"America/New_York"}"#
                .utf8
        )
        let legacyDecoded = try JSONDecoder().decode(CivilMoment.self, from: legacyPayload)
        let legacyUTC = try legacyDecoded.toUTCComponents()
        #expect(legacyUTC.hour == 5)
        #expect(legacyUTC.minute == 30)
    }

    @Test func siderealTimeMatchesMomentCacheAndLongitudeWrapping() throws {
        let moment = try CivilMoment(
            year: 2000,
            month: 1,
            day: 1,
            hour: 12,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )

        let gast = SiderealTime.gast(
            jdUT: moment.julianDayUT,
            nutationLongitude: moment.nutationLongitude,
            trueObliquity: moment.trueObliquity
        )
        AstroCoreTestSupport.expectCircularlyEqual(
            gast,
            AstroCalculator.localSiderealTimeDegrees(for: moment, longitude: 0.0),
            tolerance: 1e-9
        )
        AstroCoreTestSupport.expectCircularlyEqual(
            AstroCalculator.localSiderealTimeDegrees(for: moment, longitude: 180.0),
            AstroCalculator.localSiderealTimeDegrees(for: moment, longitude: -180.0),
            tolerance: 1e-9
        )
        #expect(gast > 280.0 && gast < 281.0)
    }

    @Test func geoCoordinateValidatesRangesAndAscendantLimit() throws {
        let boundary = try GeoCoordinate(latitude: 85.0, longitude: 180.0)
        try boundary.validateForAscendant()

        #expect(throws: AstroError.invalidCoordinate(
            detail: "latitude must be finite, got inf"
        )) {
            _ = try GeoCoordinate(latitude: .infinity, longitude: 0.0)
        }
        #expect(throws: AstroError.invalidCoordinate(
            detail: "Latitude 91.0 out of range -90...90"
        )) {
            _ = try GeoCoordinate(latitude: 91.0, longitude: 0.0)
        }
        #expect(throws: AstroError.invalidCoordinate(
            detail: "Longitude 181.0 out of range -180...180"
        )) {
            _ = try GeoCoordinate(latitude: 0.0, longitude: 181.0)
        }

        let extreme = try GeoCoordinate(latitude: 85.1, longitude: 0.0)
        #expect(throws: AstroError.extremeLatitude) {
            try extreme.validateForAscendant()
        }
    }
}
