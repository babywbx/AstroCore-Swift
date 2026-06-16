@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

@Suite("Rise Set Baselines")
struct RiseSetBaselineTests {
    private static var enabled: Bool {
        ProcessInfo.processInfo.environment["ASTROCORE_ENABLE_BASELINE_VERIFICATION"] == "1"
    }

    private func greenwich() throws -> GeoCoordinate {
        try GeoCoordinate(latitude: 51.5, longitude: 0.0)
    }

    private func dayStartUT() throws -> Double {
        try AstroCalculator.julianDayUT(for: CivilMoment(
            year: 2020, month: 3, day: 20, hour: 0, minute: 0, timeZoneIdentifier: "UTC"
        ))
    }

    @Test func sunUpperTransitMatchesReference() throws {
        guard Self.enabled else { return }
        let coordinate = try greenwich()
        let start = try dayStartUT()
        let mine = try #require(AstroCalculator.transitJulianDaysUT(
            of: .sun, observerLongitude: coordinate.longitude, kind: .upper,
            fromJulianDayUT: start, throughJulianDayUT: start + 1.2
        ).first)
        let reference = try #require(try AstrologyTestSupport.referenceRiseTransit(
            jdStartUT: start, bodyIndex: 0, longitude: coordinate.longitude,
            latitude: coordinate.latitude, event: 4
        ))
        let diffSeconds = abs(mine - reference) * 86400.0
        #expect(diffSeconds < 30.0, "transit diff = \(diffSeconds)s")
    }

    @Test func sunRiseAndSetMatchReference() throws {
        guard Self.enabled else { return }
        let coordinate = try greenwich()
        let start = try dayStartUT()
        let myRise = try #require(AstroCalculator.riseJulianDaysUT(
            of: .sun, coordinate: coordinate, fromJulianDayUT: start, throughJulianDayUT: start + 1.2
        ).first)
        let referenceRise = try #require(try AstrologyTestSupport.referenceRiseTransit(
            jdStartUT: start, bodyIndex: 0, longitude: coordinate.longitude,
            latitude: coordinate.latitude, event: 1
        ))
        let riseDiff = abs(myRise - referenceRise) * 86400.0
        #expect(riseDiff < 120.0, "rise diff = \(riseDiff)s")

        let mySet = try #require(AstroCalculator.setJulianDaysUT(
            of: .sun, coordinate: coordinate, fromJulianDayUT: start, throughJulianDayUT: start + 1.2
        ).first)
        let referenceSet = try #require(try AstrologyTestSupport.referenceRiseTransit(
            jdStartUT: start, bodyIndex: 0, longitude: coordinate.longitude,
            latitude: coordinate.latitude, event: 2
        ))
        let setDiff = abs(mySet - referenceSet) * 86400.0
        #expect(setDiff < 120.0, "set diff = \(setDiff)s")
    }
}
