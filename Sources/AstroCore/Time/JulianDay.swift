import Foundation

// Meeus Ch.7 — Julian Day Number
enum JulianDay {
    /// J2000.0 epoch: 2000-01-01 12:00 TT = JD 2451545.0
    static let j2000: Double = 2451545.0

    /// Compute JD_UT from UTC date components.
    /// Meeus formula valid for Gregorian calendar (after 1582-10-15).
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

    /// Compute JD_UT from CivilMoment (converts to UTC first).
    static func julianDay(for moment: CivilMoment) throws(AstroError) -> Double {
        let utc = try moment.utcFractionalComponents()
        return julianDay(year: utc.year, month: utc.month, dayFraction: utc.dayFraction)
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
