import Foundation

public struct CivilMoment: Sendable, Hashable, Codable {
    public let year: Int        // 1800...2100
    public let month: Int       // 1...12
    public let day: Int         // 1...31
    public let hour: Int        // 0...23
    public let minute: Int      // 0...59
    public let second: Int      // 0...59
    public let timeZoneIdentifier: String // IANA, e.g. "America/New_York"

    private let cachedDecimalYear: Double
    private let utcYear: Int
    private let utcMonth: Int
    private let utcDay: Int
    private let utcHour: Int
    private let utcMinute: Int
    private let utcSecond: Int
    private let cachedJulianDayUT: Double
    private let cachedDeltaT: Double
    private let cachedJulianCenturiesTT: Double
    private let cachedJulianMillenniaTT: Double

    private static let utcTimeZone = TimeZone(identifier: "UTC")!

    public init(
        year: Int, month: Int, day: Int,
        hour: Int, minute: Int, second: Int = 0,
        timeZoneIdentifier: String
    ) throws(AstroError) {
        guard (1800...2100).contains(year) else {
            throw .unsupportedYearRange(year)
        }
        guard (1...12).contains(month) else {
            throw .invalidCivilMoment(detail: "Month \(month) out of range 1...12")
        }
        let maxDay = Validation.daysInMonth(month: month, year: year)
        guard (1...maxDay).contains(day) else {
            throw .invalidCivilMoment(
                detail: "Day \(day) out of range 1...\(maxDay) for \(year)-\(month)")
        }
        guard (0...23).contains(hour) else {
            throw .invalidCivilMoment(detail: "Hour \(hour) out of range 0...23")
        }
        guard (0...59).contains(minute) else {
            throw .invalidCivilMoment(detail: "Minute \(minute) out of range 0...59")
        }
        guard (0...59).contains(second) else {
            throw .invalidCivilMoment(detail: "Second \(second) out of range 0...59")
        }
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            throw .invalidTimeZoneIdentifier(timeZoneIdentifier)
        }

        let utc = try Self.resolveUTCComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            timeZoneIdentifier: timeZoneIdentifier,
            timeZone: timeZone
        )
        let decimalYear = Double(year) + (Double(month) - 0.5) / 12.0
        let dayFraction =
            Double(utc.day) + Double(utc.hour) / 24.0 + Double(utc.minute) / 1440.0
            + Double(utc.second) / 86400.0
        let julianDayUT = JulianDay.julianDay(
            year: utc.year,
            month: utc.month,
            dayFraction: dayFraction
        )
        let deltaT = DeltaT.deltaT(decimalYear: decimalYear)
        let julianCenturiesTT = JulianDay.julianCenturiesTT(
            jdUT: julianDayUT,
            deltaT: deltaT
        )
        let julianMillenniaTT = JulianDay.julianMillenniaTT(
            jdUT: julianDayUT,
            deltaT: deltaT
        )

        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.timeZoneIdentifier = timeZoneIdentifier
        self.cachedDecimalYear = decimalYear
        self.utcYear = utc.year
        self.utcMonth = utc.month
        self.utcDay = utc.day
        self.utcHour = utc.hour
        self.utcMinute = utc.minute
        self.utcSecond = utc.second
        self.cachedJulianDayUT = julianDayUT
        self.cachedDeltaT = deltaT
        self.cachedJulianCenturiesTT = julianCenturiesTT
        self.cachedJulianMillenniaTT = julianMillenniaTT
    }

    /// Decimal year for ΔT lookup, e.g. 2000.5 ≈ July 2000.
    /// Uses Espenak & Meeus formula: y = year + (month - 0.5) / 12
    public var decimalYear: Double {
        cachedDecimalYear
    }

    var julianDayUT: Double { cachedJulianDayUT }
    var deltaT: Double { cachedDeltaT }
    var julianCenturiesTT: Double { cachedJulianCenturiesTT }
    var julianMillenniaTT: Double { cachedJulianMillenniaTT }

    /// Convert to UTC date components using explicit Gregorian calendar.
    func toUTCComponents() throws(AstroError) -> DateComponents {
        var components = DateComponents()
        components.year = utcYear
        components.month = utcMonth
        components.day = utcDay
        components.hour = utcHour
        components.minute = utcMinute
        components.second = utcSecond
        components.timeZone = Self.utcTimeZone
        return components
    }

    /// Fractional day in UTC for Julian Day computation.
    func utcFractionalComponents() throws(AstroError) -> (
        year: Int, month: Int, dayFraction: Double
    ) {
        let dayFraction =
            Double(utcDay) + Double(utcHour) / 24.0 + Double(utcMinute) / 1440.0
            + Double(utcSecond) / 86400.0
        return (utcYear, utcMonth, dayFraction)
    }

    public static func == (lhs: CivilMoment, rhs: CivilMoment) -> Bool {
        lhs.year == rhs.year
            && lhs.month == rhs.month
            && lhs.day == rhs.day
            && lhs.hour == rhs.hour
            && lhs.minute == rhs.minute
            && lhs.second == rhs.second
            && lhs.timeZoneIdentifier == rhs.timeZoneIdentifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(year)
        hasher.combine(month)
        hasher.combine(day)
        hasher.combine(hour)
        hasher.combine(minute)
        hasher.combine(second)
        hasher.combine(timeZoneIdentifier)
    }

    private enum CodingKeys: String, CodingKey {
        case year, month, day, hour, minute, second, timeZoneIdentifier
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self = try Self(
            year: container.decode(Int.self, forKey: .year),
            month: container.decode(Int.self, forKey: .month),
            day: container.decode(Int.self, forKey: .day),
            hour: container.decode(Int.self, forKey: .hour),
            minute: container.decode(Int.self, forKey: .minute),
            second: container.decode(Int.self, forKey: .second),
            timeZoneIdentifier: container.decode(String.self, forKey: .timeZoneIdentifier)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(year, forKey: .year)
        try container.encode(month, forKey: .month)
        try container.encode(day, forKey: .day)
        try container.encode(hour, forKey: .hour)
        try container.encode(minute, forKey: .minute)
        try container.encode(second, forKey: .second)
        try container.encode(timeZoneIdentifier, forKey: .timeZoneIdentifier)
    }

    private static func resolveUTCComponents(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        timeZoneIdentifier: String,
        timeZone: TimeZone
    ) throws(AstroError) -> (
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int
    ) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.calendar = calendar
        components.timeZone = timeZone

        // Reject DST gaps (spring-forward non-representable wall times)
        guard components.isValidDate(in: calendar) else {
            throw .invalidCivilMoment(
                detail: "Local time is not representable in \(timeZoneIdentifier)"
            )
        }

        guard let date = calendar.date(from: components) else {
            throw .dateConversionFailed
        }

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = utcTimeZone
        let utc = utcCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )

        guard let utcYear = utc.year,
            let utcMonth = utc.month,
            let utcDay = utc.day,
            let utcHour = utc.hour,
            let utcMinute = utc.minute,
            let utcSecond = utc.second
        else {
            throw .dateConversionFailed
        }

        return (
            year: utcYear,
            month: utcMonth,
            day: utcDay,
            hour: utcHour,
            minute: utcMinute,
            second: utcSecond
        )
    }
}
