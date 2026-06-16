import Foundation

/// Julian Day Number
enum JulianDay {
    /// J2000.0 epoch: 2000-01-01 12:00 TT = JD 2451545.0
    static let j2000: Double = 2451545.0

    /// Compute JD_UT from UTC date components.
    /// Valid for Gregorian calendar (after 1582-10-15).
    static func julianDay(
        year: Int, month: Int, dayFraction: Double
    ) -> Double {
        var y = Double(year)
        var m = Double(month)

        if m <= 2 {
            y -= 1
            m += 12
        }

        let a = floor(y / 100.0)
        let b = 2.0 - a + floor(a / 4.0)

        return floor(365.25 * (y + 4716.0))
            + floor(30.6001 * (m + 1.0))
            + dayFraction + b - 1524.5
    }

    /// Inverse of `julianDay(year:month:dayFraction:)`: the Gregorian civil date and
    /// time-of-day for a JD. `secondsOfDay` ∈ [0, 86400). Valid for Gregorian dates.
    static func calendarDate(julianDay jd: Double)
        -> (year: Int, month: Int, day: Int, secondsOfDay: Double)
    {
        let shifted = jd + 0.5
        let z = floor(shifted)
        let dayFraction = shifted - z
        let alpha = floor((z - 1867216.25) / 36524.25)
        let a = z + 1.0 + alpha - floor(alpha / 4.0)
        let b = a + 1524.0
        let c = floor((b - 122.1) / 365.25)
        let d = floor(365.25 * c)
        let e = floor((b - d) / 30.6001)
        let day = b - d - floor(30.6001 * e)
        let month = e < 14.0 ? e - 1.0 : e - 13.0
        let year = month > 2.0 ? c - 4716.0 : c - 4715.0
        return (
            year: Int(year),
            month: Int(month),
            day: Int(day),
            secondsOfDay: dayFraction * 86400.0
        )
    }

    /// Julian centuries from J2000.0 (T_UT)
    static func julianCenturiesUT(jd: Double) -> Double {
        (jd - j2000) / 36525.0
    }

    /// Julian centuries in TT from J2000.0 (T_TT)
    static func julianCenturiesTT(jdUT: Double, deltaT: Double) -> Double {
        let jdTT = jdUT + deltaT / 86400.0
        return (jdTT - j2000) / 36525.0
    }

    /// Julian millennia from J2000.0 in TT (τ for VSOP87D)
    static func julianMillenniaTT(jdUT: Double, deltaT: Double) -> Double {
        let jdTT = jdUT + deltaT / 86400.0
        return (jdTT - j2000) / 365250.0
    }
}
