import Foundation

extension AstroCalculator {
    private static let stationSampleStepDays = 2.0
    private static let stationMaxSamplesDivisor = 16.0
    private static let stationSlopeStepDays = 0.5
    private static let stationSpeedTolerance = 1e-8 // deg/day
    private static let stationRootTolDays = 1e-7

    /// Longitude acceleration (deg/day²) by central difference of speed; the Newton slope at a
    /// station, and the sign that classifies it.
    private static func longitudeAcceleration(
        of body: CelestialBody, julianDayTT jd: Double
    ) -> Double {
        let lo = longitudeSpeed(of: body, julianDayTT: jd - stationSlopeStepDays)
        let hi = longitudeSpeed(of: body, julianDayTT: jd + stationSlopeStepDays)
        return (hi - lo) / (2.0 * stationSlopeStepDays)
    }

    private static func stationTuning(step: Double) -> RootSolver.Tuning {
        RootSolver.Tuning(
            step: step,
            valueTolerance: stationSpeedTolerance,
            stepTolerance: stationRootTolDays
        )
    }

    /// JD(TT) of the nearest longitude-speed zero (station) to the seed; nil if none in the window
    /// (e.g. the Sun, Moon, and mean node never reverse).
    public static func stationJulianDayTT(
        of body: CelestialBody,
        nearJulianDayTT jd: Double,
        searchWindowDays window: Double = 120.0
    ) -> Double? {
        let step = min(stationSampleStepDays, 2.0 * window / stationMaxSamplesDivisor)
        return RootSolver.nearestRoot(
            near: jd,
            window: window,
            tuning: stationTuning(step: step),
            value: { longitudeSpeed(of: body, julianDayTT: $0) },
            slope: { longitudeAcceleration(of: body, julianDayTT: $0) }
        )
    }

    /// UT variant: solve in TT, then invert ΔT (jdUT = jdTT − ΔT(jdUT)/86400), mirroring
    /// `exactAspectJulianDayUT`.
    public static func stationJulianDayUT(
        of body: CelestialBody,
        nearJulianDayUT jd: Double,
        searchWindowDays window: Double = 120.0
    ) -> Double? {
        let seedTT = jd + deltaTSeconds(julianDayUT: jd) / 86400.0
        guard let stationTT = stationJulianDayTT(
            of: body, nearJulianDayTT: seedTT, searchWindowDays: window
        ) else { return nil }
        var jdUT = stationTT
        for _ in 0..<8 {
            let next = stationTT - deltaTSeconds(julianDayUT: jdUT) / 86400.0
            if abs(next - jdUT) < 1e-9 {
                jdUT = next
                break
            }
            jdUT = next
        }
        return jdUT
    }

    /// Direction of motion change at a station: `.retrograde` when the speed turns from positive to
    /// negative (acceleration < 0), `.direct` otherwise.
    public static func stationKind(of body: CelestialBody, julianDayTT jd: Double) -> StationKind {
        longitudeAcceleration(of: body, julianDayTT: jd) < 0 ? .retrograde : .direct
    }

    /// All station JDs in the closed TT interval, ordered by time, via a forward sign-change scan.
    public static func stationJulianDaysTT(
        of body: CelestialBody,
        fromJulianDayTT start: Double,
        throughJulianDayTT end: Double
    ) -> [Double] {
        RootSolver.roots(
            from: start,
            through: end,
            tuning: stationTuning(step: stationSampleStepDays),
            value: { longitudeSpeed(of: body, julianDayTT: $0) },
            slope: { longitudeAcceleration(of: body, julianDayTT: $0) }
        )
    }
}
