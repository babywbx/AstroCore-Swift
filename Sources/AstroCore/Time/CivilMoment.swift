import Foundation

public struct CivilMoment: Sendable, Hashable, Codable {
    private struct LocalTimeRequest {
        let year: Int
        let month: Int
        let day: Int
        let hour: Int
        let minute: Int
        let second: Int
        let timeZoneIdentifier: String
        let repeatedTimeResolution: RepeatedTimeResolution
    }

    public let year: Int // 1800...2100
    public let month: Int // 1...12
    public let day: Int // 1...31
    public let hour: Int // 0...23
    public let minute: Int // 0...59
    public let second: Int // 0...59
    public let timeZoneIdentifier: String // IANA, e.g. "America/New_York"
    public let repeatedTimeResolution: RepeatedTimeResolution

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
    private let cachedNutationLongitude: Double
    private let cachedTrueObliquity: Double
    private let cachedGreenwichApparentSiderealTime: Double

    private static let utcTimeZone = TimeZone(identifier: "UTC")!

    public init(
        year: Int, month: Int, day: Int,
        hour: Int, minute: Int, second: Int = 0,
        timeZoneIdentifier: String,
        repeatedTimeResolution: RepeatedTimeResolution = .reject
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
                detail: "Day \(day) out of range 1...\(maxDay) for \(year)-\(month)"
            )
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
            request: LocalTimeRequest(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second,
                timeZoneIdentifier: timeZoneIdentifier,
                repeatedTimeResolution: repeatedTimeResolution
            ),
            timeZone: timeZone
        )
        // Use exact UTC fractional year for Delta T interpolation.
        let decimalYear = Self.fractionalYear(
            year: utc.year,
            month: utc.month,
            day: utc.day,
            hour: utc.hour,
            minute: utc.minute,
            second: utc.second
        )
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
        let nutation = Nutation.compute(julianCenturiesTT: julianCenturiesTT)
        let meanObliquity = Obliquity.meanObliquity(
            julianCenturiesTT: julianCenturiesTT
        )
        let trueObliquity = meanObliquity + nutation.obliquity / 3600.0
        let greenwichApparentSiderealTime = SiderealTime.gast(
            jdUT: julianDayUT,
            nutationLongitude: nutation.longitude,
            trueObliquity: trueObliquity
        )

        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.timeZoneIdentifier = timeZoneIdentifier
        self.repeatedTimeResolution = repeatedTimeResolution
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
        self.cachedNutationLongitude = nutation.longitude
        self.cachedTrueObliquity = trueObliquity
        self.cachedGreenwichApparentSiderealTime = greenwichApparentSiderealTime
    }

    /// Decimal year for Delta T lookup, based on the exact UTC instant.
    var decimalYear: Double {
        cachedDecimalYear
    }

    var julianDayUT: Double { cachedJulianDayUT }
    var deltaT: Double { cachedDeltaT }
    var julianCenturiesTT: Double { cachedJulianCenturiesTT }
    var julianMillenniaTT: Double { cachedJulianMillenniaTT }
    var nutationLongitude: Double { cachedNutationLongitude }
    public var trueObliquity: Double { cachedTrueObliquity }
    var greenwichApparentSiderealTime: Double { cachedGreenwichApparentSiderealTime }

    @inline(__always)
    public func localApparentSiderealTime(longitude: Double) -> Double {
        AngleMath.normalized(degrees: cachedGreenwichApparentSiderealTime + longitude)
    }

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

    public static func == (lhs: CivilMoment, rhs: CivilMoment) -> Bool {
        lhs.year == rhs.year
            && lhs.month == rhs.month
            && lhs.day == rhs.day
            && lhs.hour == rhs.hour
            && lhs.minute == rhs.minute
            && lhs.second == rhs.second
            && lhs.timeZoneIdentifier == rhs.timeZoneIdentifier
            && lhs.utcYear == rhs.utcYear
            && lhs.utcMonth == rhs.utcMonth
            && lhs.utcDay == rhs.utcDay
            && lhs.utcHour == rhs.utcHour
            && lhs.utcMinute == rhs.utcMinute
            && lhs.utcSecond == rhs.utcSecond
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(year)
        hasher.combine(month)
        hasher.combine(day)
        hasher.combine(hour)
        hasher.combine(minute)
        hasher.combine(second)
        hasher.combine(timeZoneIdentifier)
        hasher.combine(utcYear)
        hasher.combine(utcMonth)
        hasher.combine(utcDay)
        hasher.combine(utcHour)
        hasher.combine(utcMinute)
        hasher.combine(utcSecond)
    }

    private enum CodingKeys: String, CodingKey {
        case year, month, day, hour, minute, second, timeZoneIdentifier
        case repeatedTimeResolution
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let year = try container.decode(Int.self, forKey: .year)
        let month = try container.decode(Int.self, forKey: .month)
        let day = try container.decode(Int.self, forKey: .day)
        let hour = try container.decode(Int.self, forKey: .hour)
        let minute = try container.decode(Int.self, forKey: .minute)
        let second = try container.decode(Int.self, forKey: .second)
        let timeZoneIdentifier = try container.decode(String.self, forKey: .timeZoneIdentifier)

        if let repeatedTimeResolution = try container.decodeIfPresent(
            RepeatedTimeResolution.self,
            forKey: .repeatedTimeResolution
        ) {
            self = try Self(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second,
                timeZoneIdentifier: timeZoneIdentifier,
                repeatedTimeResolution: repeatedTimeResolution
            )
            return
        }

        if let decoded = try? Self(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            timeZoneIdentifier: timeZoneIdentifier,
            repeatedTimeResolution: .reject
        ) {
            self = decoded
        } else {
            self = try Self(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second,
                timeZoneIdentifier: timeZoneIdentifier,
                repeatedTimeResolution: .firstOccurrence
            )
        }
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
        try container.encode(repeatedTimeResolution, forKey: .repeatedTimeResolution)
    }

    private static func resolveUTCComponents(
        request: LocalTimeRequest,
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
        components.year = request.year
        components.month = request.month
        components.day = request.day
        components.hour = request.hour
        components.minute = request.minute
        components.second = request.second
        components.calendar = calendar
        components.timeZone = timeZone

        // Reject DST gaps (spring-forward non-representable wall times)
        guard components.isValidDate(in: calendar) else {
            throw .invalidCivilMoment(
                detail: "Local time is not representable in \(request.timeZoneIdentifier)"
            )
        }

        let date = try resolveLocalDate(
            matching: components,
            in: calendar,
            timeZoneIdentifier: request.timeZoneIdentifier,
            repeatedTimeResolution: request.repeatedTimeResolution
        )

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

    private static func resolveLocalDate(
        matching components: DateComponents,
        in calendar: Calendar,
        timeZoneIdentifier: String,
        repeatedTimeResolution: RepeatedTimeResolution
    ) throws(AstroError) -> Date {
        guard let first = exactLocalDate(
            matching: components,
            in: calendar,
            repeatedTimePolicy: .first
        ), let last = exactLocalDate(
            matching: components,
            in: calendar,
            repeatedTimePolicy: .last
        ) else {
            throw .dateConversionFailed
        }

        guard first != last else {
            return first
        }

        switch repeatedTimeResolution {
        case .reject:
            throw .invalidCivilMoment(
                detail: """
                Local time is ambiguous in \(timeZoneIdentifier); pass repeatedTimeResolution \
                to choose the first or last occurrence
                """
            )
        case .firstOccurrence:
            return first
        case .lastOccurrence:
            return last
        }
    }

    private static func exactLocalDate(
        matching components: DateComponents,
        in calendar: Calendar,
        repeatedTimePolicy: Calendar.RepeatedTimePolicy
    ) -> Date? {
        var dayComponents = DateComponents()
        dayComponents.year = components.year
        dayComponents.month = components.month
        dayComponents.day = components.day
        dayComponents.calendar = calendar
        dayComponents.timeZone = components.timeZone

        guard let dayStart = calendar.date(from: dayComponents) else {
            return nil
        }

        return calendar.nextDate(
            after: dayStart.addingTimeInterval(-1),
            matching: components,
            matchingPolicy: .strict,
            repeatedTimePolicy: repeatedTimePolicy,
            direction: .forward
        )
    }

    private static func fractionalYear(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int
    ) -> Double {
        let daysBeforeMonth = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
        var dayOfYear = daysBeforeMonth[month - 1] + day
        if month > 2 && Validation.daysInMonth(month: 2, year: year) == 29 {
            dayOfYear += 1
        }

        let fractionOfDay = (
            Double(hour) / 24.0
                + Double(minute) / 1440.0
                + Double(second) / 86400.0
        )
        let daysInYear = Validation.daysInMonth(month: 2, year: year) == 29 ? 366.0 : 365.0
        return Double(year) + (Double(dayOfYear - 1) + fractionOfDay) / daysInYear
    }
}
