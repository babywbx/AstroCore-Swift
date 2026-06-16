import AstroCore
import Foundation

extension AstrologyCalculator {
    /// Widen the scan past the query so an interval already in progress at either edge still yields
    /// both physical endpoints; covers the longest single retrograde lobe (outer planets, ~½ year).
    private static let retrogradeSearchMarginDays = 220.0

    /// All stations of a body within [from, to] (civil moments), ordered by time.
    public static func stations(
        of body: CelestialBody, from: CivilMoment, to: CivilMoment
    ) -> [Station] {
        AstroCalculator.stationJulianDaysTT(
            of: body, fromJulianDayTT: from.julianDayTT, throughJulianDayTT: to.julianDayTT
        )
        .map { station(of: body, julianDayTT: $0) }
    }

    /// Retrograde intervals overlapping [from, to], each a complete retrograde→direct pair.
    public static func retrogradePeriods(
        of body: CelestialBody, from: CivilMoment, to: CivilMoment
    ) -> [RetrogradeInterval] {
        let stations = AstroCalculator.stationJulianDaysTT(
            of: body,
            fromJulianDayTT: from.julianDayTT - retrogradeSearchMarginDays,
            throughJulianDayTT: to.julianDayTT + retrogradeSearchMarginDays
        )
        .map { station(of: body, julianDayTT: $0) }

        var intervals: [RetrogradeInterval] = []
        var index = 0
        while index < stations.count {
            let current = stations[index]
            let hasClosingDirect = index + 1 < stations.count && stations[index + 1].kind == .direct
            if current.kind == .retrograde, hasClosingDirect {
                intervals.append(
                    RetrogradeInterval(body: body, start: current, end: stations[index + 1])
                )
                index += 2
            } else {
                index += 1
            }
        }

        let lowUT = from.julianDayUT
        let highUT = to.julianDayUT
        return intervals.filter { $0.start.julianDayUT <= highUT && $0.end.julianDayUT >= lowUT }
    }

    private static func station(of body: CelestialBody, julianDayTT: Double) -> Station {
        Station(
            body: body,
            kind: AstroCalculator.stationKind(of: body, julianDayTT: julianDayTT),
            julianDayUT: AstroCalculator.julianDayUT(fromJulianDayTT: julianDayTT),
            longitude: AstroCalculator.eclipticLongitude(of: body, julianDayTT: julianDayTT)
        )
    }
}
