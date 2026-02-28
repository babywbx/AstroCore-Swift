import Foundation

public struct CivilMoment: Sendable, Hashable, Codable {
    public let year: Int        // 1800...2100
    public let month: Int       // 1...12
    public let day: Int         // 1...31
    public let hour: Int        // 0...23
    public let minute: Int      // 0...59
    public let second: Int      // 0...59
    public let timeZoneIdentifier: String // IANA, e.g. "America/New_York"

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
        guard TimeZone(identifier: timeZoneIdentifier) != nil else {
            throw .invalidTimeZoneIdentifier(timeZoneIdentifier)
        }

        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    /// Decimal year for ΔT lookup, e.g. 2000.5 ≈ July 2000.
    /// Uses Espenak & Meeus formula: y = year + (month - 0.5) / 12
    public var decimalYear: Double {
        Double(year) + (Double(month) - 0.5) / 12.0
    }

    /// Convert to UTC date components using explicit Gregorian calendar.
    func toUTCComponents() throws(AstroError) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        let tz = TimeZone(identifier: timeZoneIdentifier)!
        calendar.timeZone = tz

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.calendar = calendar
        components.timeZone = tz

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
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!

        return utcCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
    }

    /// Fractional day in UTC for Julian Day computation.
    func utcFractionalComponents() throws(AstroError) -> (
        year: Int, month: Int, dayFraction: Double
    ) {
        let utc = try toUTCComponents()
        guard let y = utc.year, let m = utc.month, let d = utc.day,
            let h = utc.hour, let min = utc.minute, let s = utc.second
        else {
            throw .dateConversionFailed
        }
        let dayFraction =
            Double(d) + Double(h) / 24.0 + Double(min) / 1440.0
            + Double(s) / 86400.0
        return (y, m, dayFraction)
    }
}
