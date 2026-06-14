@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

struct AscendantRegressionCase: Sendable, CustomStringConvertible {
    let name: String
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let timeZoneIdentifier: String
    let latitude: Double
    let longitude: Double
    let expectedLongitude: Double
    let tolerance: Double
    let expectedSign: ZodiacSign

    var description: String { name }
}

private let ascendantRegressionCases: [AscendantRegressionCase] = [
    .init(name: "new-york", year: 1990, month: 8, day: 15, hour: 14, minute: 30, timeZoneIdentifier: "America/New_York", latitude: 40.7128, longitude: -74.0060, expectedLongitude: 240.93003034223938, tolerance: 0.000001, expectedSign: .sagittarius),
    .init(name: "london", year: 2000, month: 1, day: 1, hour: 0, minute: 0, timeZoneIdentifier: "Europe/London", latitude: 51.5074, longitude: -0.1278, expectedLongitude: 186.94, tolerance: 0.5, expectedSign: .libra),
    .init(name: "tokyo", year: 1985, month: 6, day: 15, hour: 8, minute: 0, timeZoneIdentifier: "Asia/Tokyo", latitude: 35.6762, longitude: 139.6503, expectedLongitude: 128.91, tolerance: 0.5, expectedSign: .leo),
    .init(name: "berlin", year: 1975, month: 9, day: 20, hour: 15, minute: 0, timeZoneIdentifier: "Europe/Berlin", latitude: 52.5200, longitude: 13.4050, expectedLongitude: 277.54, tolerance: 0.5, expectedSign: .capricorn)
]

@Suite("Ascendant and Natal")
struct AscendantAndNatalTests {
    @Test(arguments: ascendantRegressionCases)
    func ascendantMatchesRegressionCases(_ testCase: AscendantRegressionCase) throws {
        let moment = try CivilMoment(
            year: testCase.year,
            month: testCase.month,
            day: testCase.day,
            hour: testCase.hour,
            minute: testCase.minute,
            timeZoneIdentifier: testCase.timeZoneIdentifier
        )
        let coordinate = try GeoCoordinate(
            latitude: testCase.latitude,
            longitude: testCase.longitude
        )

        let result = try AstrologyCalculator.ascendant(for: moment, coordinate: coordinate)
        #expect(abs(result.eclipticLongitude - testCase.expectedLongitude) < testCase.tolerance)
        #expect(result.sign == testCase.expectedSign)
        #expect(result.degreeInSign >= 0.0 && result.degreeInSign < 30.0)
        AstrologyTestSupport.expectValidLongitude(result.eclipticLongitude)
    }

    @Test func ascendantSupportsSouthernHemisphereAndDateLineConsistency() throws {
        let sydney = try AstrologyTestSupport.sydney2010()
        let sydneyAscendant = try AstrologyCalculator.ascendant(
            for: sydney.moment,
            coordinate: sydney.coordinate
        )
        AstrologyTestSupport.expectValidLongitude(sydneyAscendant.eclipticLongitude)

        let moment = try CivilMoment(
            year: 2000,
            month: 6,
            day: 1,
            hour: 12,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let west = try GeoCoordinate(latitude: 0.0, longitude: 180.0)
        let east = try GeoCoordinate(latitude: 0.0, longitude: -180.0)
        let western = try AstrologyCalculator.ascendant(for: moment, coordinate: west)
        let eastern = try AstrologyCalculator.ascendant(for: moment, coordinate: east)

        AstrologyTestSupport.expectCircularlyEqual(
            AstroCalculator.localSiderealTimeDegrees(
                for: moment,
                longitude: west.longitude
            ),
            AstroCalculator.localSiderealTimeDegrees(
                for: moment,
                longitude: east.longitude
            ),
            tolerance: 0.001
        )
        AstrologyTestSupport.expectCircularlyEqual(
            western.eclipticLongitude,
            eastern.eclipticLongitude,
            tolerance: 1e-9
        )
    }

    @Test func ascendantRejectsExtremeLatitudeBoundary() throws {
        let moment = try CivilMoment(
            year: 2000,
            month: 6,
            day: 21,
            hour: 12,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )

        let valid = try GeoCoordinate(latitude: 84.9, longitude: 0.0)
        let result = try AstrologyCalculator.ascendant(for: moment, coordinate: valid)
        AstrologyTestSupport.expectValidLongitude(result.eclipticLongitude)

        let invalid = try GeoCoordinate(latitude: 85.1, longitude: 0.0)
        #expect(throws: AstrologyError.core(.extremeLatitude)) {
            try AstrologyCalculator.ascendant(for: moment, coordinate: invalid)
        }
    }

    @Test func natalPositionsRequireCoordinateForAscendant() throws {
        let moment = try CivilMoment(
            year: 2000,
            month: 1,
            day: 1,
            hour: 12,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )

        #expect(throws: AstrologyError.missingCoordinateForAscendant) {
            _ = try AstrologyCalculator.natalPositions(
                for: moment,
                bodies: [.sun],
                includeAscendant: true
            )
        }
    }

    @Test func natalPositionsHandleEmptyAndSubsetRequests() throws {
        let moment = try CivilMoment(
            year: 2000,
            month: 1,
            day: 1,
            hour: 12,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )

        let empty = try AstrologyCalculator.natalPositions(for: moment, bodies: [])
        #expect(empty.bodies.isEmpty)
        #expect(empty.ascendant == nil)

        let subset = try AstrologyCalculator.natalPositions(
            for: moment,
            bodies: [.sun, .moon]
        )
        #expect(subset.bodies.count == 2)
        #expect(subset.bodies[.sun]?.body == .sun)
        #expect(subset.bodies[.moon]?.body == .moon)
        #expect(subset.ascendant == nil)
    }

    @Test func natalPositionsMatchSingleBodyCalculations() throws {
        let fixture = try AstrologyTestSupport.newYork1990()

        let sun = AstroCalculator.sunPosition(for: fixture.moment)
        let moon = AstroCalculator.moonPosition(for: fixture.moment)
        let mercury = AstroCalculator.planetPosition(.mercury, for: fixture.moment)
        let ascendant = try AstrologyCalculator.ascendant(
            for: fixture.moment,
            coordinate: fixture.coordinate
        )

        let natal = try AstrologyCalculator.natalPositions(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            bodies: [.sun, .moon, .mercury],
            includeAscendant: true
        )

        #expect(natal.bodies[.sun] == sun)
        #expect(natal.bodies[.moon] == moon)
        #expect(natal.bodies[.mercury] == mercury)
        #expect(natal.ascendant == ascendant)
    }

    @Test func natalStatesMatchPositionsAndSingleBodyMotion() throws {
        let fixture = try AstrologyTestSupport.newYork1990()
        let bodies: Set<CelestialBody> = [.sun, .moon, .mercury]

        let positions = try AstrologyCalculator.natalPositions(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            bodies: bodies,
            includeAscendant: true
        )
        let states = try AstrologyCalculator.natalStates(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            bodies: bodies,
            includeAscendant: true
        )

        #expect(states.ascendant == positions.ascendant)
        #expect(states.bodies.count == positions.bodies.count)
        for body in bodies {
            let state = try #require(states.bodies[body])
            #expect(state.position == positions.bodies[body])
            let single = AstroCalculator.celestialState(body, for: fixture.moment)
            #expect(abs(state.speed - single.speed) < 1e-12)
        }
    }

    @Test func natalChartCombinesPositionsHousesAndContext() throws {
        let fixture = try AstrologyTestSupport.newYork1990()

        let chart = try AstrologyCalculator.natalChart(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            bodies: Set(CelestialBody.allCases),
            system: .placidus
        )

        #expect(chart.positions.bodies.count == CelestialBody.allCases.count)
        #expect(chart.positions.ascendant != nil)
        #expect(chart.houses.requestedSystem == .placidus)
        #expect(chart.houses.resolvedSystem == .placidus)
        #expect(chart.moment == fixture.moment)
        #expect(chart.coordinate == fixture.coordinate)
        AstrologyTestSupport.expectCircularlyEqual(
            chart.positions.ascendant?.eclipticLongitude ?? -1.0,
            chart.houses.angles.ascendant,
            tolerance: 1e-9
        )
    }
}
