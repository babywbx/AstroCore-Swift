@testable import AstroCore
import Foundation
import Testing

@Suite("Rise Set Transit")
struct RiseSetTests {
    private func julianDayUT(_ year: Int, _ month: Int, _ day: Int, _ hour: Int) throws -> Double {
        try CivilMoment(
            year: year, month: month, day: day, hour: hour, minute: 0,
            timeZoneIdentifier: "UTC"
        ).julianDayUT
    }

    private func greenwich() throws -> GeoCoordinate {
        try GeoCoordinate(latitude: 51.5, longitude: 0.0)
    }

    @Test func upperTransitHasZeroHourAngle() throws {
        let seed = try julianDayUT(2020, 3, 20, 12)
        let transit = try #require(AstroCalculator.transitJulianDayUT(
            of: .sun, observerLongitude: 0.0, kind: .upper, nearJulianDayUT: seed
        ))
        let hourAngle = AstroCalculator.hourAngleDegrees(
            of: .sun, atJulianDayUT: transit, observerLongitude: 0.0
        )
        #expect(abs(hourAngle) < 1e-6)
    }

    @Test func lowerTransitHasHourAngle180() throws {
        let seed = try julianDayUT(2020, 3, 20, 0)
        let transit = try #require(AstroCalculator.transitJulianDayUT(
            of: .sun, observerLongitude: 0.0, kind: .lower, nearJulianDayUT: seed
        ))
        let hourAngle = AstroCalculator.hourAngleDegrees(
            of: .sun, atJulianDayUT: transit, observerLongitude: 0.0
        )
        #expect(abs(abs(hourAngle) - 180.0) < 1e-6)
    }

    @Test func riseAndSetSitOnTheStandardAltitude() throws {
        let coordinate = try greenwich()
        let rise = try #require(try AstroCalculator.riseJulianDayUT(
            of: .sun, coordinate: coordinate, nearJulianDayUT: julianDayUT(2020, 3, 20, 6)
        ))
        let set = try #require(try AstroCalculator.setJulianDayUT(
            of: .sun, coordinate: coordinate, nearJulianDayUT: julianDayUT(2020, 3, 20, 18)
        ))
        #expect(abs(AstroCalculator.altitudeAboveStandardDegrees(
            of: .sun, atJulianDayUT: rise, coordinate: coordinate
        )) < 1e-6)
        #expect(abs(AstroCalculator.altitudeAboveStandardDegrees(
            of: .sun, atJulianDayUT: set, coordinate: coordinate
        )) < 1e-6)
    }

    @Test func riseClimbsAndSetDescends() throws {
        let coordinate = try greenwich()
        let rise = try #require(try AstroCalculator.riseJulianDayUT(
            of: .sun, coordinate: coordinate, nearJulianDayUT: julianDayUT(2020, 3, 20, 6)
        ))
        let set = try #require(try AstroCalculator.setJulianDayUT(
            of: .sun, coordinate: coordinate, nearJulianDayUT: julianDayUT(2020, 3, 20, 18)
        ))
        let before = AstroCalculator.topocentricAltitudeDegrees(of: .sun, atJulianDayUT: rise - 0.01, coordinate: coordinate)
        let after = AstroCalculator.topocentricAltitudeDegrees(of: .sun, atJulianDayUT: rise + 0.01, coordinate: coordinate)
        #expect(after > before) // rising
        let beforeSet = AstroCalculator.topocentricAltitudeDegrees(of: .sun, atJulianDayUT: set - 0.01, coordinate: coordinate)
        let afterSet = AstroCalculator.topocentricAltitudeDegrees(of: .sun, atJulianDayUT: set + 0.01, coordinate: coordinate)
        #expect(afterSet < beforeSet) // setting
    }

    @Test func sunriseTransitSunsetAreOrdered() throws {
        let coordinate = try greenwich()
        let rise = try #require(try AstroCalculator.riseJulianDayUT(
            of: .sun, coordinate: coordinate, nearJulianDayUT: julianDayUT(2020, 3, 20, 6)
        ))
        let transit = try #require(try AstroCalculator.transitJulianDayUT(
            of: .sun, observerLongitude: 0.0, kind: .upper, nearJulianDayUT: julianDayUT(2020, 3, 20, 12)
        ))
        let set = try #require(try AstroCalculator.setJulianDayUT(
            of: .sun, coordinate: coordinate, nearJulianDayUT: julianDayUT(2020, 3, 20, 18)
        ))
        #expect(rise < transit)
        #expect(transit < set)
    }

    @Test func meridianAltitudeMatchesLatitudeDeclination() throws {
        let coordinate = try greenwich()
        let transit = try #require(try AstroCalculator.transitJulianDayUT(
            of: .sun, observerLongitude: 0.0, kind: .upper, nearJulianDayUT: julianDayUT(2020, 3, 20, 12)
        ))
        let jdTT = transit + AstroCalculator.deltaTSeconds(julianDayUT: transit) / 86400.0
        let dec = AstroCalculator.equatorial(of: .sun, julianDayTT: jdTT).declination
        let altitude = AstroCalculator.topocentricAltitudeDegrees(of: .sun, atJulianDayUT: transit, coordinate: coordinate)
        #expect(abs(altitude - (90.0 - abs(coordinate.latitude - dec))) < 0.5)
    }

    @Test func midnightSunNeverSets() throws {
        let svalbard = try GeoCoordinate(latitude: 78.0, longitude: 15.0)
        let set = try AstroCalculator.setJulianDayUT(
            of: .sun, coordinate: svalbard, nearJulianDayUT: julianDayUT(2020, 6, 21, 12)
        )
        #expect(set == nil)
        // Sun stays above the horizon even at local midnight.
        let midnight = try AstroCalculator.topocentricAltitudeDegrees(
            of: .sun, atJulianDayUT: julianDayUT(2020, 6, 21, 23), coordinate: svalbard
        )
        #expect(midnight > 0)
    }

    @Test func polarNightNeverRises() throws {
        let svalbard = try GeoCoordinate(latitude: 78.0, longitude: 15.0)
        let rise = try AstroCalculator.riseJulianDayUT(
            of: .sun, coordinate: svalbard, nearJulianDayUT: julianDayUT(2020, 12, 21, 12)
        )
        #expect(rise == nil)
        let noon = try AstroCalculator.topocentricAltitudeDegrees(
            of: .sun, atJulianDayUT: julianDayUT(2020, 12, 21, 11), coordinate: svalbard
        )
        #expect(noon < 0)
    }
}
