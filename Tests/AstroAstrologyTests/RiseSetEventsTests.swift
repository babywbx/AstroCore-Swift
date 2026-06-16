@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

@Suite("Rise Set Events")
struct RiseSetEventsTests {
    private func greenwich() throws -> GeoCoordinate {
        try GeoCoordinate(latitude: 51.5, longitude: 0.0)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, tz: String = "UTC") throws -> CivilMoment {
        try CivilMoment(year: year, month: month, day: day, hour: 12, minute: 0, timeZoneIdentifier: tz)
    }

    @Test func sunEventsAreOrderedAndOnHorizon() throws {
        let coordinate = try greenwich()
        let events = try AstrologyCalculator.riseSetEvents(of: .sun, on: date(2020, 3, 20), coordinate: coordinate)
        let rise = try #require(events.rise)
        let upper = try #require(events.upperTransit)
        let set = try #require(events.set)
        #expect(rise.julianDayUT < upper.julianDayUT)
        #expect(upper.julianDayUT < set.julianDayUT)
        #expect(!events.circumpolar)
        #expect(!events.neverRises)
        #expect(abs(AstroCalculator.altitudeAboveStandardDegrees(
            of: .sun, atJulianDayUT: rise.julianDayUT, coordinate: coordinate
        )) < 1e-6)
        #expect(abs(AstroCalculator.altitudeAboveStandardDegrees(
            of: .sun, atJulianDayUT: set.julianDayUT, coordinate: coordinate
        )) < 1e-6)
    }

    @Test func eventInstantCivilTimeMatchesJulianDay() throws {
        let events = try AstrologyCalculator.riseSetEvents(of: .sun, on: date(2020, 3, 20), coordinate: greenwich())
        let rise = try #require(events.rise)
        #expect(abs(rise.civilMoment.julianDayUT - rise.julianDayUT) < 1e-9)
        #expect(rise.civilMoment.timeZoneIdentifier == "UTC")
    }

    @Test func eventsRenderInRequestedLocalDay() throws {
        let nyc = try GeoCoordinate(latitude: 40.7, longitude: -74.0)
        let events = try AstrologyCalculator.riseSetEvents(
            of: .sun, on: date(2020, 3, 20, tz: "America/New_York"), coordinate: nyc
        )
        let rise = try #require(events.rise)
        let set = try #require(events.set)
        #expect(rise.civilMoment.day == 20)
        #expect(set.civilMoment.day == 20)
        #expect(rise.civilMoment.timeZoneIdentifier == "America/New_York")
    }

    @Test func circumpolarSunNeverSets() throws {
        let svalbard = try GeoCoordinate(latitude: 78.0, longitude: 15.0)
        let events = try AstrologyCalculator.riseSetEvents(
            of: .sun, on: date(2020, 6, 21, tz: "UTC"), coordinate: svalbard
        )
        #expect(events.circumpolar)
        #expect(!events.neverRises)
        #expect(events.rise == nil)
        #expect(events.set == nil)
    }

    @Test func polarNightSunNeverRises() throws {
        let svalbard = try GeoCoordinate(latitude: 78.0, longitude: 15.0)
        let events = try AstrologyCalculator.riseSetEvents(
            of: .sun, on: date(2020, 12, 21, tz: "UTC"), coordinate: svalbard
        )
        #expect(events.neverRises)
        #expect(!events.circumpolar)
        #expect(events.rise == nil)
        #expect(events.set == nil)
    }

    @Test func eventsCodableRoundTripPreservesJulianDay() throws {
        let events = try AstrologyCalculator.riseSetEvents(of: .sun, on: date(2020, 3, 20), coordinate: greenwich())
        let data = try JSONEncoder().encode(events)
        let decoded = try JSONDecoder().decode(RiseSetEvents.self, from: data)
        let rise = try #require(events.rise)
        let decodedRise = try #require(decoded.rise)
        #expect(abs(decodedRise.julianDayUT - rise.julianDayUT) < 1e-12)
    }

    @Test func civilTwilightBracketsSunrise() throws {
        let coordinate = try greenwich()
        let day = try date(2020, 3, 20)
        let events = try AstrologyCalculator.riseSetEvents(of: .sun, on: day, coordinate: coordinate)
        let rise = try #require(events.rise)
        let twilight = try AstrologyCalculator.twilight(depressionDegrees: 6.0, on: day, coordinate: coordinate)
        let dawn = try #require(twilight.dawn)
        let dusk = try #require(twilight.dusk)
        #expect(dawn.julianDayUT < rise.julianDayUT)
        #expect(dusk.julianDayUT > rise.julianDayUT)
        // Sun centre sits 6° below the horizon at dawn.
        #expect(abs(AstroCalculator.topocentricAltitudeDegrees(
            of: .sun, atJulianDayUT: dawn.julianDayUT, coordinate: coordinate
        ) + 6.0) < 1e-5)
    }
}
