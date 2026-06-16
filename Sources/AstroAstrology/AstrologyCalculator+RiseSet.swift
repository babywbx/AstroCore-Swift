import AstroCore
import Foundation

extension AstrologyCalculator {
    /// Rise / set / transits for the civil day containing `date` at `coordinate`.
    public static func riseSetEvents(
        of body: CelestialBody, on date: CivilMoment, coordinate: GeoCoordinate,
        applyRefraction: Bool = true
    ) throws(AstrologyError) -> RiseSetEvents {
        do {
            let window = try civilDayWindow(for: date)
            let timeZone = date.timeZoneIdentifier

            let riseSetCrossings = AstroCalculator.riseSetCrossingsUT(
                of: body, coordinate: coordinate,
                fromJulianDayUT: window.startUT, throughJulianDayUT: window.endUT,
                applyRefraction: applyRefraction
            )
            let riseUT = riseSetCrossings.first { $0.rising && $0.julianDayUT < window.endUT }?.julianDayUT
            let setUT = riseSetCrossings.first { !$0.rising && $0.julianDayUT < window.endUT }?.julianDayUT
            let upperUT = AstroCalculator.transitJulianDaysUT(
                of: body, observerLongitude: coordinate.longitude, kind: .upper,
                fromJulianDayUT: window.startUT, throughJulianDayUT: window.endUT
            ).first { $0 < window.endUT }
            let lowerUT = AstroCalculator.transitJulianDaysUT(
                of: body, observerLongitude: coordinate.longitude, kind: .lower,
                fromJulianDayUT: window.startUT, throughJulianDayUT: window.endUT
            ).first { $0 < window.endUT }

            var circumpolar = false
            var neverRises = false
            if riseUT == nil, setUT == nil {
                let sample = upperUT ?? (0.5 * (window.startUT + window.endUT))
                let residual = AstroCalculator.altitudeAboveStandardDegrees(
                    of: body, atJulianDayUT: sample, coordinate: coordinate, applyRefraction: applyRefraction
                )
                if residual > 0 { circumpolar = true } else { neverRises = true }
            }

            return try RiseSetEvents(
                body: body,
                rise: instant(riseUT, timeZoneIdentifier: timeZone),
                set: instant(setUT, timeZoneIdentifier: timeZone),
                upperTransit: instant(upperUT, timeZoneIdentifier: timeZone),
                lowerTransit: instant(lowerUT, timeZoneIdentifier: timeZone),
                circumpolar: circumpolar,
                neverRises: neverRises
            )
        } catch {
            throw AstrologyError.core(error)
        }
    }

    /// Sun depression twilight (e.g. 6 / 12 / 18°) for the civil day containing `date`.
    public static func twilight(
        depressionDegrees: Double, on date: CivilMoment, coordinate: GeoCoordinate
    ) throws(AstrologyError) -> (dawn: EventInstant?, dusk: EventInstant?) {
        do {
            let window = try civilDayWindow(for: date)
            let target = -depressionDegrees
            let crossings = AstroCalculator.altitudeCrossingEventsUT(
                of: .sun, coordinate: coordinate, targetAltitudeDegrees: target,
                fromJulianDayUT: window.startUT, throughJulianDayUT: window.endUT
            )
            let dawnUT = crossings.first { $0.rising && $0.julianDayUT < window.endUT }?.julianDayUT
            let duskUT = crossings.first { !$0.rising && $0.julianDayUT < window.endUT }?.julianDayUT
            return try (
                dawn: instant(dawnUT, timeZoneIdentifier: date.timeZoneIdentifier),
                dusk: instant(duskUT, timeZoneIdentifier: date.timeZoneIdentifier)
            )
        } catch {
            throw AstrologyError.core(error)
        }
    }

    private struct CivilDayWindow {
        let startUT: Double
        let endUT: Double
    }

    /// Half-open UT window [local midnight, next local midnight) for `date`'s civil day.
    private static func civilDayWindow(for date: CivilMoment) throws(AstroError) -> CivilDayWindow {
        let timeZone = date.timeZoneIdentifier
        let startUT = try CivilMoment(
            year: date.year, month: date.month, day: date.day,
            hour: 0, minute: 0, second: 0, timeZoneIdentifier: timeZone
        ).julianDayUT
        // Midday of the next civil day, resolved through the bridge to get its calendar date.
        let nextNoon = try CivilMoment(julianDayUT: startUT + 1.5, timeZoneIdentifier: timeZone)
        let endUT = try CivilMoment(
            year: nextNoon.year, month: nextNoon.month, day: nextNoon.day,
            hour: 0, minute: 0, second: 0, timeZoneIdentifier: timeZone
        ).julianDayUT
        return CivilDayWindow(startUT: startUT, endUT: endUT)
    }

    private static func instant(
        _ julianDayUT: Double?, timeZoneIdentifier: String
    ) throws(AstroError) -> EventInstant? {
        guard let julianDayUT else { return nil }
        return try EventInstant(
            julianDayUT: julianDayUT,
            civilMoment: CivilMoment(julianDayUT: julianDayUT, timeZoneIdentifier: timeZoneIdentifier)
        )
    }
}
