@testable import AstroCore
import Foundation
import Testing

struct SolarRegressionCase: Sendable, CustomStringConvertible {
    let name: String
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let expectedLongitude: Double
    let tolerance: Double

    var description: String { name }
}

struct BodyPositionCase: Sendable, CustomStringConvertible {
    let name: String
    let body: CelestialBody
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let expectedLongitude: Double?
    let expectedLatitude: Double?

    var description: String { name }
}

private let solarRegressionCases: [SolarRegressionCase] = [
    .init(name: "epoch-2000", year: 2000, month: 1, day: 1, hour: 12, minute: 0, expectedLongitude: 280.3689148247274, tolerance: 0.000001),
    .init(name: "solstice-2000", year: 2000, month: 6, day: 21, hour: 12, minute: 0, expectedLongitude: 90.40625104814757, tolerance: 0.001),
    .init(name: "equinox-1990", year: 1990, month: 3, day: 20, hour: 12, minute: 0, expectedLongitude: 359.614, tolerance: 0.05),
    .init(name: "solstice-2024", year: 2024, month: 12, day: 21, hour: 12, minute: 0, expectedLongitude: 270.113, tolerance: 0.05)
]

private let extendedBodyAccuracyCases: [BodyPositionCase] = [
    .init(
        name: "uranus-longitude-edge",
        body: .uranus,
        year: 1899, month: 12, day: 1, hour: 0, minute: 0,
        expectedLongitude: 248.296821574,
        expectedLatitude: nil
    ),
    .init(
        name: "uranus-latitude-edge",
        body: .uranus,
        year: 1896, month: 11, day: 16, hour: 12, minute: 0,
        expectedLongitude: nil,
        expectedLatitude: 0.236490860
    ),
    .init(
        name: "neptune-longitude-edge",
        body: .neptune,
        year: 2083, month: 8, day: 1, hour: 0, minute: 0,
        expectedLongitude: 129.577726717,
        expectedLatitude: nil
    ),
    .init(
        name: "neptune-latitude-edge",
        body: .neptune,
        year: 1912, month: 7, day: 16, hour: 12, minute: 0,
        expectedLongitude: nil,
        expectedLatitude: -0.512178376
    ),
    .init(
        name: "uranus-solar-deflection-edge",
        body: .uranus,
        year: 1817, month: 12, day: 8, hour: 6, minute: 0,
        expectedLongitude: 255.988430139,
        expectedLatitude: -0.037128115
    ),
    .init(
        name: "neptune-solar-deflection-edge",
        body: .neptune,
        year: 2084, month: 8, day: 3, hour: 3, minute: 0,
        expectedLongitude: 131.816609853,
        expectedLatitude: -0.027377952
    ),
    .init(
        name: "pluto-2100-boundary",
        body: .pluto,
        year: 2100, month: 12, day: 16, hour: 12, minute: 0,
        expectedLongitude: 33.509115667,
        expectedLatitude: -16.951662015
    )
]

private let distanceRangeCases: [(CelestialBody, ClosedRange<Double>)] = [
    (.sun, 0.95...1.05),
    (.moon, 0.00235...0.00275),
    (.mercury, 0.5...1.6),
    (.venus, 0.25...1.8),
    (.mars, 0.35...2.7),
    (.jupiter, 3.5...6.5),
    (.saturn, 7.0...11.0),
    (.uranus, 17.0...22.5),
    (.neptune, 28.0...32.0),
    (.pluto, 28.0...36.0)
]

private let outerPlanetDistanceAccuracyCases: [(CelestialBody, Int, Int, Int, Double)] = [
    (.uranus, 1800, 1, 1, 18.047734991716),
    (.neptune, 2026, 6, 14, 30.062782126122),
    (.pluto, 1800, 1, 1, 41.519157904199)
]

@Suite("Ephemeris Regression")
struct EphemerisRegressionTests {
    @Test(arguments: solarRegressionCases)
    func sunMatchesRegressionAnchors(_ testCase: SolarRegressionCase) throws {
        let moment = try CivilMoment(
            year: testCase.year,
            month: testCase.month,
            day: testCase.day,
            hour: testCase.hour,
            minute: testCase.minute,
            timeZoneIdentifier: "UTC"
        )
        let position = AstroCalculator.sunPosition(for: moment)
        #expect(abs(position.longitude - testCase.expectedLongitude) < testCase.tolerance)
        #expect(position.body == .sun)
    }

    @Test func moonMatchesBaselineAndDailyMotion() throws {
        let baselineMoment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        let baseline = AstroCalculator.moonPosition(for: baselineMoment)
        #expect(abs(baseline.longitude - 223.32433584412911) < 0.000001)
        #expect(abs(baseline.latitude - 5.17) < 0.5)
        #expect(baseline.body == .moon)

        let nextDay = try CivilMoment(
            year: 2000, month: 6, day: 2, hour: 0, minute: 0, timeZoneIdentifier: "UTC"
        )
        let priorDay = try CivilMoment(
            year: 2000, month: 6, day: 1, hour: 0, minute: 0, timeZoneIdentifier: "UTC"
        )
        let prior = AstroCalculator.moonPosition(for: priorDay)
        let later = AstroCalculator.moonPosition(for: nextDay)
        let motion = AngleMath.normalized(degrees: later.longitude - prior.longitude)
        #expect(motion > 11.0 && motion < 15.0)
    }

    @Test func planetsMatchRegressionSnapshotAtJ2000() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        let expectations: [(CelestialBody, Double)] = [
            (.mercury, 271.8892835562328),
            (.venus, 241.56581962641636),
            (.mars, 327.9633109921631),
            (.jupiter, 25.25310593667188),
            (.saturn, 40.39564718958692),
            (.uranus, 314.8091879148923),
            (.neptune, 303.1930050584793),
            (.pluto, 251.45482311198222)
        ]
        for (body, expectedLongitude) in expectations {
            let position = AstroCalculator.planetPosition(body, for: moment)
            #expect(abs(position.longitude - expectedLongitude) < 0.000001)
            #expect(position.body == body)
            #expect(position.latitude.isFinite)
        }
    }

    @Test(arguments: extendedBodyAccuracyCases)
    func extendedBodiesStayWithinAccuracyEnvelope(_ testCase: BodyPositionCase) throws {
        let moment = try CivilMoment(
            year: testCase.year,
            month: testCase.month,
            day: testCase.day,
            hour: testCase.hour,
            minute: testCase.minute,
            timeZoneIdentifier: "UTC"
        )
        let position = AstroCalculator.planetPosition(testCase.body, for: moment)
        let oneArcsecond = 1.0 / 3600.0
        if let expectedLongitude = testCase.expectedLongitude {
            AstroCoreTestSupport.expectCircularlyEqual(
                position.longitude,
                expectedLongitude,
                tolerance: oneArcsecond,
                testCase.name
            )
        }
        if let expectedLatitude = testCase.expectedLatitude {
            #expect(abs(position.latitude - expectedLatitude) < oneArcsecond)
        }
    }

    @Test func plutoDistanceMatchesBoundarySnapshot() throws {
        let moment = try CivilMoment(
            year: 2100, month: 12, day: 16, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        let distance = try #require(AstroCalculator.planetPosition(.pluto, for: moment).distance)
        #expect(abs(distance - 48.385661680926) < 0.00005)
    }

    @Test(arguments: outerPlanetDistanceAccuracyCases)
    func outerPlanetDistancesMatchAccuracySnapshots(
        _ body: CelestialBody,
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ expectedDistance: Double
    ) throws {
        let moment = try CivilMoment(
            year: year, month: month, day: day, hour: 0, minute: 0, timeZoneIdentifier: "UTC"
        )
        let distance = try #require(AstroCalculator.planetPosition(body, for: moment).distance)
        #expect(abs(distance - expectedDistance) < 0.00001)
    }

    @Test func unifiedPlanetAPIMatchesDirectSunAndMoonPaths() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 15, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        let sunDirect = AstroCalculator.sunPosition(for: moment)
        let sunViaUnified = AstroCalculator.planetPosition(.sun, for: moment)
        #expect(sunDirect == sunViaUnified)

        let moonDirect = AstroCalculator.moonPosition(for: moment)
        let moonViaUnified = AstroCalculator.planetPosition(.moon, for: moment)
        #expect(moonDirect == moonViaUnified)
    }

    @Test func realBodiesExposeGeocentricDistances() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        let bodies = Set(distanceRangeCases.map(\.0) + [CelestialBody.meanNode, .trueNode, .lilith, .trueLilith])
        let batched = AstroCalculator.positions(of: bodies, at: moment)
        let states = AstroCalculator.states(of: bodies, at: moment)

        for (body, range) in distanceRangeCases {
            let direct = AstroCalculator.planetPosition(body, for: moment)
            let distance = try #require(direct.distance)
            #expect(distance.isFinite)
            #expect(range.contains(distance))
            #expect(try #require(batched[body]).distance == direct.distance)
            let state = try #require(states[body])
            #expect(state.distance == direct.distance)
            #expect(state.position.distance == direct.distance)
        }

        for point in [CelestialBody.meanNode, .trueNode, .lilith, .trueLilith] {
            #expect(AstroCalculator.planetPosition(point, for: moment).distance == nil)
            #expect(try #require(batched[point]).distance == nil)
            let state = try #require(states[point])
            #expect(state.distance == nil)
            #expect(state.position.distance == nil)
        }
    }

    @Test func computedPointsMatchSnapshotAtJ2000() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        #expect(abs(AstroCalculator.planetPosition(.meanNode, for: moment).longitude - 125.0406471653018) < 1e-9)
        #expect(abs(AstroCalculator.planetPosition(.trueNode, for: moment).longitude - 123.95361473775787) < 1e-9)
        #expect(abs(AstroCalculator.planetPosition(.lilith, for: moment).longitude - 263.3488857119409) < 1e-9)
        for point in [CelestialBody.meanNode, .trueNode, .lilith] {
            #expect(AstroCalculator.planetPosition(point, for: moment).latitude == 0.0)
        }
        // trueLilith carries ecliptic latitude (projected mean apogee).
        #expect(AstroCalculator.planetPosition(.trueLilith, for: moment).latitude != 0.0)
    }

    @Test func lightCorrectionsStayWithinExpectedBounds() {
        let elongations = [1.0, 5.0, 10.0, 30.0, 45.0, 90.0, 120.0]
        for elongation in elongations {
            let deflection = PlanetaryPosition.gravitationalDeflectionArcsec(
                elongationDeg: elongation
            )
            #expect(deflection > 0.0)
        }
        #expect(
            abs(PlanetaryPosition.gravitationalDeflectionArcsec(elongationDeg: 90.0) - 0.00407) < 1e-6
        )
        #expect(
            abs(PlanetaryPosition.gravitationalDeflectionArcsec(elongationDeg: 0.5) - 0.8768032086) < 1e-6
        )
        #expect(abs(PlanetaryPosition.gravitationalDeflectionArcsec(elongationDeg: 180.0)) < 1e-9)
        #expect(abs(PlanetaryPosition.fk5LongitudeCorrectionArcsec() - -0.09033) < 0.001)
        #expect(PlanetResiduals.correctionArcsec(for: .mercury, t: 0.0) != 0.0)
    }
}
