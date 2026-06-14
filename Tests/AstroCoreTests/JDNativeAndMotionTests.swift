@testable import AstroCore
import Foundation
import Testing

@Suite("JD-native and motion")
struct JDNativeAndMotionTests {
    @Test func jdNativeLongitudeMatchesCivilMomentPath() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 15, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let jdTT = moment.julianDayUT + moment.deltaT / 86400.0

        for body in CelestialBody.allCases {
            let viaCivil = AstroCalculator.planetPosition(body, for: moment).longitude
            let viaJD = AstroCalculator.eclipticLongitude(of: body, julianDayTT: jdTT)
            #expect(abs(viaCivil - viaJD) < 1e-7, "\(body): \(viaCivil) vs \(viaJD)")
        }
    }

    @Test func utVariantAppliesDeltaT() {
        let jdUT = 2451545.0
        let dt = AstroCalculator.deltaTSeconds(julianDayUT: jdUT)
        #expect(dt > 60.0 && dt < 70.0)

        let viaUT = AstroCalculator.eclipticLongitude(of: .sun, julianDayUT: jdUT)
        let viaTT = AstroCalculator.eclipticLongitude(
            of: .sun,
            julianDayTT: jdUT + dt / 86400.0
        )
        #expect(abs(viaUT - viaTT) < 1e-12)
    }

    @Test func longitudeSpeedMatchesFiniteDifference() {
        let jdTT = 2451545.0
        let sun = AstroCalculator.longitudeSpeed(of: .sun, julianDayTT: jdTT)
        #expect(sun > 0.95 && sun < 1.02)

        let moon = AstroCalculator.longitudeSpeed(of: .moon, julianDayTT: jdTT)
        #expect(moon > 11.0 && moon < 15.0)

        let h = 0.25
        let lo = AstroCalculator.eclipticLongitude(of: .mars, julianDayTT: jdTT - h)
        let hi = AstroCalculator.eclipticLongitude(of: .mars, julianDayTT: jdTT + h)
        var diff = hi - lo
        if diff > 180.0 { diff -= 360.0 }
        if diff < -180.0 { diff += 360.0 }
        let expected = diff / (2.0 * h)
        #expect(
            abs(AstroCalculator.longitudeSpeed(of: .mars, julianDayTT: jdTT) - expected)
                < 1e-9
        )
    }

    @Test func celestialStateMatchesPositionAndSpeedPrimitive() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 15, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let jdTT = moment.julianDayUT + moment.deltaT / 86400.0

        for body in CelestialBody.allCases {
            let state = AstroCalculator.celestialState(body, for: moment)
            let position = AstroCalculator.planetPosition(body, for: moment)
            #expect(state.position == position)
            #expect(abs(state.speed - AstroCalculator.longitudeSpeed(of: body, julianDayTT: jdTT)) < 1e-12)
        }
    }

    @Test func axisPrimitivesMatchPublicCalculatorWrappers() throws {
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30,
            timeZoneIdentifier: "America/New_York"
        )
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let last = moment.localApparentSiderealTime(longitude: coord.longitude)
        let obl = moment.trueObliquity

        let ascDirect = Axis.ascendantLongitude(
            lastDegrees: last, trueObliquityDegrees: obl, latitudeDegrees: coord.latitude
        )
        let ascWrapped = try AstroCalculator.ascendantLongitude(for: moment, coordinate: coord)
        #expect(abs(ascDirect - ascWrapped) < 1e-12)
        #expect(ascDirect >= 0.0 && ascDirect < 360.0)

        let mcDirect = Axis.midheavenLongitude(lastDegrees: last, trueObliquityDegrees: obl)
        let mcWrapped = AstroCalculator.midheavenLongitude(for: moment, coordinate: coord)
        #expect(abs(mcDirect - mcWrapped) < 1e-12)
    }
}
