@testable import AstroCore
import Testing

@Suite("Equatorial Coordinate")
struct EquatorialCoordinateTests {
    /// J2000 mean obliquity, a clean fixed constant for the pure-rotation anchors.
    private let obliquity = 23.4392911

    @Test func eclipticOriginMapsToEquatorialOrigin() {
        let eq = EquatorialCoordinate.from(
            eclipticLongitudeDegrees: 0.0, latitudeDegrees: 0.0, trueObliquityDegrees: obliquity
        )
        AstroCoreTestSupport.expectCircularlyEqual(eq.rightAscension, 0.0, tolerance: 1e-9, "ra")
        #expect(abs(eq.declination - 0.0) < 1e-9)
    }

    @Test func quarterPointOnEclipticHitsObliquityDeclination() {
        let eq = EquatorialCoordinate.from(
            eclipticLongitudeDegrees: 90.0, latitudeDegrees: 0.0, trueObliquityDegrees: obliquity
        )
        AstroCoreTestSupport.expectCircularlyEqual(eq.rightAscension, 90.0, tolerance: 1e-9, "ra")
        #expect(abs(eq.declination - obliquity) < 1e-9)
    }

    @Test func threeQuarterPointGivesNegativeObliquityDeclination() {
        let eq = EquatorialCoordinate.from(
            eclipticLongitudeDegrees: 270.0, latitudeDegrees: 0.0, trueObliquityDegrees: obliquity
        )
        AstroCoreTestSupport.expectCircularlyEqual(eq.rightAscension, 270.0, tolerance: 1e-9, "ra")
        #expect(abs(eq.declination - -obliquity) < 1e-9)
    }

    @Test func northEclipticPoleMapsToObliquityComplement() {
        // β = +90° → δ = 90° − ε, RA = 270° (the ecliptic north pole in equatorial of date).
        let eq = EquatorialCoordinate.from(
            eclipticLongitudeDegrees: 123.0, latitudeDegrees: 90.0, trueObliquityDegrees: obliquity
        )
        #expect(abs(eq.declination - (90.0 - obliquity)) < 1e-9)
        AstroCoreTestSupport.expectCircularlyEqual(eq.rightAscension, 270.0, tolerance: 1e-9, "ra")
    }
}
