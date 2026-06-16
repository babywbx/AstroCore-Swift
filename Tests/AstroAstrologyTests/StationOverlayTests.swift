@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

@Suite("Station Overlay")
struct StationOverlayTests {
    private func moment(_ year: Int, _ month: Int, _ day: Int) throws -> CivilMoment {
        try CivilMoment(
            year: year, month: month, day: day, hour: 0, minute: 0,
            timeZoneIdentifier: "UTC"
        )
    }

    @Test func stationsAlternateAcrossYear() throws {
        let stations = try AstrologyCalculator.stations(
            of: .mercury, from: moment(2020, 1, 1), to: moment(2021, 1, 1)
        )
        #expect(stations.count == 6)
        #expect(zip(stations, stations.dropFirst()).allSatisfy { $0.julianDayUT < $1.julianDayUT })
        for (index, station) in stations.enumerated() {
            #expect(station.body == .mercury)
            #expect(station.kind == (index.isMultiple(of: 2) ? .retrograde : .direct))
            #expect(station.longitude >= 0 && station.longitude < 360)
        }
    }

    @Test func retrogradePeriodsArePaired() throws {
        let periods = try AstrologyCalculator.retrogradePeriods(
            of: .mercury, from: moment(2020, 1, 1), to: moment(2021, 1, 1)
        )
        #expect(periods.count == 3)
        for period in periods {
            #expect(period.start.kind == .retrograde)
            #expect(period.end.kind == .direct)
            #expect(period.start.julianDayUT < period.end.julianDayUT)
            // Mid-interval the body moves retrograde (negative longitude speed).
            let mid = 0.5 * (period.start.julianDayUT + period.end.julianDayUT)
            let midSpeed = AstroCalculator.longitudeSpeed(
                of: .mercury,
                julianDayTT: mid + AstroCalculator.deltaTSeconds(julianDayUT: mid) / 86400.0
            )
            #expect(midSpeed < 0)
        }
    }

    @Test func retrogradePeriodExtendsBeyondQueryWindow() throws {
        // Query window sits entirely inside the Feb–Mar 2020 Mercury retrograde.
        let periods = try AstrologyCalculator.retrogradePeriods(
            of: .mercury, from: moment(2020, 2, 25), to: moment(2020, 3, 1)
        )
        #expect(periods.count == 1)
        let period = try #require(periods.first)
        #expect(try period.start.julianDayUT < moment(2020, 2, 25).julianDayUT)
        #expect(try period.end.julianDayUT > moment(2020, 3, 1).julianDayUT)
        #expect(period.start.kind == .retrograde)
        #expect(period.end.kind == .direct)
    }

    @Test func nonRetrogradingBodyHasNoPeriods() throws {
        let from = try moment(2020, 1, 1)
        let to = try moment(2021, 1, 1)
        #expect(AstrologyCalculator.stations(of: .sun, from: from, to: to).isEmpty)
        #expect(AstrologyCalculator.retrogradePeriods(of: .sun, from: from, to: to).isEmpty)
    }

    @Test func stationAndIntervalAreCodable() throws {
        let periods = try AstrologyCalculator.retrogradePeriods(
            of: .mercury, from: moment(2020, 1, 1), to: moment(2021, 1, 1)
        )
        let period = try #require(periods.first)
        let data = try JSONEncoder().encode(period)
        let decoded = try JSONDecoder().decode(RetrogradeInterval.self, from: data)
        #expect(decoded == period)
    }
}
