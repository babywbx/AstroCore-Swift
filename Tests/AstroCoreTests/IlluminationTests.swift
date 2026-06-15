@testable import AstroCore
import Testing

@Suite("Illumination")
struct IlluminationTests {
    private let litBodies: [CelestialBody] = [
        .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto
    ]

    @Test func rangesAreValid() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 13, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        for body in litBodies {
            let illum = try #require(AstroCalculator.illumination(of: body, at: moment))
            #expect((0.0...180.0).contains(illum.phaseAngle))
            #expect((0.0...1.0).contains(illum.illuminatedFraction))
            #expect((0.0...180.0).contains(illum.elongation))
        }
    }

    @Test func nilForSunAndComputedPoints() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 13, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        for body in [CelestialBody.sun, .meanNode, .trueNode, .lilith, .trueLilith] {
            #expect(AstroCalculator.illumination(of: body, at: moment) == nil)
        }
    }

    @Test func moonFractionTracksSyzygies() throws {
        let newMoon = try CivilMoment(
            year: 2000, month: 1, day: 6, hour: 18, minute: 14, timeZoneIdentifier: "UTC"
        )
        let fullMoon = try CivilMoment(
            year: 2000, month: 1, day: 21, hour: 4, minute: 40, timeZoneIdentifier: "UTC"
        )
        #expect(try #require(AstroCalculator.illumination(of: .moon, at: newMoon)).illuminatedFraction < 0.02)
        #expect(try #require(AstroCalculator.illumination(of: .moon, at: fullMoon)).illuminatedFraction > 0.98)
    }

    // TODO(a4c): fill from local reference capture (controller will drive). MEASURED, NOT FABRICATED.
    // Moon + Venus illuminated fraction / phase angle at 2000-01-13 12:00:00 UTC; tolerance set at capture.
    // @Test func illuminationMatchesIndependentAnchors() throws {
    //     let moment = try CivilMoment(year: 2000, month: 1, day: 13, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
    //     let tolFraction = MEASURED_TOL_FRACTION
    //     let tolDegrees = MEASURED_TOL_DEG
    //     let moon = try #require(AstroCalculator.illumination(of: .moon, at: moment))
    //     #expect(abs(moon.illuminatedFraction - MEASURED_MOON_FRACTION) < tolFraction)
    //     #expect(abs(moon.phaseAngle - MEASURED_MOON_PHASE) < tolDegrees)
    //     let venus = try #require(AstroCalculator.illumination(of: .venus, at: moment))
    //     #expect(abs(venus.illuminatedFraction - MEASURED_VENUS_FRACTION) < tolFraction)
    // }
}
