@testable import AstroCore
import Foundation
import Testing

@Suite("Stations")
struct StationTests {
    private func julianDayTT(_ year: Int, _ month: Int, _ day: Int) throws -> Double {
        try CivilMoment(
            year: year, month: month, day: day, hour: 0, minute: 0,
            timeZoneIdentifier: "UTC"
        ).julianDayTT
    }

    @Test func stationLandsWhereSpeedIsZero() throws {
        let seed = try julianDayTT(2020, 2, 17)
        let station = AstroCalculator.stationJulianDayTT(
            of: .mercury, nearJulianDayTT: seed, searchWindowDays: 30.0
        )
        #expect(station != nil)
        let speed = AstroCalculator.longitudeSpeed(of: .mercury, julianDayTT: station ?? .nan)
        #expect(abs(speed) < 1e-7)
    }

    @Test func stationKindMatchesSpeedTransition() throws {
        let seed = try julianDayTT(2020, 2, 17)
        let station = try #require(AstroCalculator.stationJulianDayTT(
            of: .mercury, nearJulianDayTT: seed, searchWindowDays: 30.0
        ))
        #expect(AstroCalculator.stationKind(of: .mercury, julianDayTT: station) == .retrograde)
        #expect(AstroCalculator.longitudeSpeed(of: .mercury, julianDayTT: station - 2.0) > 0)
        #expect(AstroCalculator.longitudeSpeed(of: .mercury, julianDayTT: station + 2.0) < 0)
    }

    @Test func nonRetrogradingBodiesHaveNoStation() throws {
        let seed = try julianDayTT(2020, 6, 1)
        for body in [CelestialBody.sun, .moon, .meanNode] {
            #expect(AstroCalculator.stationJulianDayTT(
                of: body, nearJulianDayTT: seed, searchWindowDays: 120.0
            ) == nil)
            #expect(AstroCalculator.stationJulianDaysTT(
                of: body, fromJulianDayTT: seed, throughJulianDayTT: seed + 200.0
            ).isEmpty)
        }
    }

    @Test func enumeratesAlternatingStationsAcrossYear() throws {
        let start = try julianDayTT(2020, 1, 1)
        let end = try julianDayTT(2021, 1, 1)
        let stations = AstroCalculator.stationJulianDaysTT(
            of: .mercury, fromJulianDayTT: start, throughJulianDayTT: end
        )
        #expect(stations.count == 6) // three retrograde periods → six stations
        // strictly increasing
        #expect(zip(stations, stations.dropFirst()).allSatisfy { $0 < $1 })
        for (index, station) in stations.enumerated() {
            #expect(abs(AstroCalculator.longitudeSpeed(of: .mercury, julianDayTT: station)) < 1e-6)
            let expected: StationKind = index.isMultiple(of: 2) ? .retrograde : .direct
            #expect(AstroCalculator.stationKind(of: .mercury, julianDayTT: station) == expected)
        }
    }

    @Test func utVariantInvertsDeltaT() throws {
        let seedUT = try CivilMoment(
            year: 2020, month: 2, day: 17, hour: 0, minute: 0, timeZoneIdentifier: "UTC"
        ).julianDayUT
        let stationUT = try #require(AstroCalculator.stationJulianDayUT(
            of: .mercury, nearJulianDayUT: seedUT, searchWindowDays: 30.0
        ))
        let stationTT = stationUT + AstroCalculator.deltaTSeconds(julianDayUT: stationUT) / 86400.0
        #expect(abs(AstroCalculator.longitudeSpeed(of: .mercury, julianDayTT: stationTT)) < 1e-7)
    }
}
