import Foundation
import Testing

@testable import AstroCore

struct SolarRegressionCase: Sendable, CustomStringConvertible {
    let name: String
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let expectedLongitude: Double
    let tolerance: Double
    let expectedSign: ZodiacSign

    var description: String { name }
}

private let solarRegressionCases: [SolarRegressionCase] = [
    .init(name: "epoch-2000", year: 2000, month: 1, day: 1, hour: 12, minute: 0, expectedLongitude: 280.3689148247274, tolerance: 0.000001, expectedSign: .capricorn),
    .init(name: "solstice-2000", year: 2000, month: 6, day: 21, hour: 12, minute: 0, expectedLongitude: 90.40625104814757, tolerance: 0.001, expectedSign: .cancer),
    .init(name: "equinox-1990", year: 1990, month: 3, day: 20, hour: 12, minute: 0, expectedLongitude: 359.614, tolerance: 0.05, expectedSign: .pisces),
    .init(name: "solstice-2024", year: 2024, month: 12, day: 21, hour: 12, minute: 0, expectedLongitude: 270.113, tolerance: 0.05, expectedSign: .capricorn),
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
        #expect(position.sign == testCase.expectedSign)
        #expect(position.body == .sun)
    }

    @Test func moonMatchesBaselineAndDailyMotion() throws {
        let baselineMoment = try CivilMoment(
            year: 2000,
            month: 1,
            day: 1,
            hour: 12,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let baseline = AstroCalculator.moonPosition(for: baselineMoment)
        #expect(abs(baseline.longitude - 223.32401040882044) < 0.000001)
        #expect(abs(baseline.latitude - 5.17) < 0.5)
        #expect(baseline.sign == .scorpio)
        #expect(baseline.body == .moon)

        let nextDay = try CivilMoment(
            year: 2000,
            month: 6,
            day: 2,
            hour: 0,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let priorDay = try CivilMoment(
            year: 2000,
            month: 6,
            day: 1,
            hour: 0,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let prior = AstroCalculator.moonPosition(for: priorDay)
        let later = AstroCalculator.moonPosition(for: nextDay)
        let motion = AngleMath.normalized(degrees: later.longitude - prior.longitude)
        #expect(motion > 11.0 && motion < 15.0)
    }

    @Test func planetsMatchRegressionSnapshotAtJ2000() throws {
        let moment = try CivilMoment(
            year: 2000,
            month: 1,
            day: 1,
            hour: 12,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let expectations: [(CelestialBody, Double, ZodiacSign)] = [
            (.mercury, 271.8892835562328, .capricorn),
            (.venus, 241.56581962641636, .sagittarius),
            (.mars, 327.9633109921631, .aquarius),
            (.jupiter, 25.25310593667188, .aries),
            (.saturn, 40.39564718958692, .taurus),
        ]

        for (body, expectedLongitude, expectedSign) in expectations {
            let position = AstroCalculator.planetPosition(body, for: moment)
            #expect(abs(position.longitude - expectedLongitude) < 0.000001)
            #expect(position.sign == expectedSign)
            #expect(position.body == body)
            #expect(position.latitude.isFinite)
        }
    }

    @Test func unifiedPlanetAPIMatchesDirectSunAndMoonPaths() throws {
        let moment = try CivilMoment(
            year: 2000,
            month: 6,
            day: 15,
            hour: 12,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )

        let sunDirect = AstroCalculator.sunPosition(for: moment)
        let sunViaUnified = AstroCalculator.planetPosition(.sun, for: moment)
        #expect(sunDirect == sunViaUnified)

        let moonDirect = AstroCalculator.moonPosition(for: moment)
        let moonViaUnified = AstroCalculator.planetPosition(.moon, for: moment)
        #expect(moonDirect == moonViaUnified)
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
            PlanetaryPosition.gravitationalDeflectionArcsec(elongationDeg: 0.5) == 0.0
        )
        #expect(
            abs(PlanetaryPosition.gravitationalDeflectionArcsec(elongationDeg: 90.0) - 0.00407)
                < 1e-6
        )
        #expect(
            abs(PlanetaryPosition.gravitationalDeflectionArcsec(elongationDeg: 180.0)) < 1e-9
        )
        #expect(abs(PlanetaryPosition.fk5LongitudeCorrectionArcsec() - (-0.09033)) < 0.001)
        #expect(PlanetResiduals.correctionArcsec(for: .mercury, t: 0.0) != 0.0)
    }
}
