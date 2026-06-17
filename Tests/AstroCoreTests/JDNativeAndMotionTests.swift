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

    @Test func retrogradeSignMatchesKnownWindows() throws {
        let cases: [(CelestialBody, Int, Int, Int, Bool)] = [
            (.mercury, 2020, 10, 20, true),
            (.mercury, 2020, 12, 1, false),
            (.mars, 2020, 10, 13, true),
            (.mars, 2021, 1, 1, false),
            (.jupiter, 2020, 7, 15, true),
            (.jupiter, 2020, 10, 15, false)
        ]

        for (body, year, month, day, expectedRetrograde) in cases {
            let moment = try CivilMoment(
                year: year, month: month, day: day, hour: 12, minute: 0,
                timeZoneIdentifier: "UTC"
            )
            let state = AstroCalculator.celestialState(body, for: moment)
            #expect(
                state.isRetrograde == expectedRetrograde,
                "\(body) \(year)-\(month)-\(day) speed=\(state.speed)"
            )
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

    @Test func jdNativeAPIsRejectNonFiniteAndOutOfRangeInputs() throws {
        let coordinate = try GeoCoordinate(latitude: 40.0, longitude: -74.0)
        let unsupportedUT = JulianDay.julianDay(year: 1799, month: 12, dayFraction: 31.0)
        let unsupportedTT = JulianDay.julianDay(year: 2101, month: 1, dayFraction: 1.0)

        for jd in [Double.nan, Double.infinity, unsupportedTT] {
            #expect(AstroCalculator.eclipticLongitude(of: .sun, julianDayTT: jd).isNaN)
            #expect(AstroCalculator.longitudeSpeed(of: .sun, julianDayTT: jd).isNaN)
            let equatorial = AstroCalculator.equatorial(of: .sun, julianDayTT: jd)
            #expect(equatorial.rightAscension.isNaN)
            #expect(equatorial.declination.isNaN)
            #expect(AstroCalculator.stationJulianDayTT(of: .mercury, nearJulianDayTT: jd) == nil)
            #expect(AstroCalculator.exactAspectJulianDayTT(
                of: .sun, and: .moon, aspectAngleDegrees: 0.0, nearJulianDayTT: jd
            ) == nil)
        }

        for jd in [Double.nan, Double.infinity, unsupportedUT] {
            #expect(AstroCalculator.deltaTSeconds(julianDayUT: jd).isNaN)
            #expect(AstroCalculator.eclipticLongitude(of: .sun, julianDayUT: jd).isNaN)
            #expect(AstroCalculator.equationOfTime(julianDayUT: jd).isNaN)
            #expect(AstroCalculator.topocentricAltitudeDegrees(
                of: .sun, atJulianDayUT: jd, coordinate: coordinate
            ).isNaN)
            #expect(AstroCalculator.hourAngleDegrees(
                of: .sun, atJulianDayUT: jd, observerLongitude: coordinate.longitude
            ).isNaN)
            #expect(AstroCalculator.riseJulianDayUT(
                of: .sun, coordinate: coordinate, nearJulianDayUT: jd
            ) == nil)
            #expect(AstroCalculator.riseJulianDaysUT(
                of: .sun, coordinate: coordinate,
                fromJulianDayUT: jd, throughJulianDayUT: jd + 1.0
            ).isEmpty)
        }
    }
}
