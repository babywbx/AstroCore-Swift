import Foundation

enum Topocentric {
    private static let earthRadiusMeters = 6378137.0
    private static let auMeters = 149597870700.0
    private static let bOverA = 0.99664719

    /// Observer (ρ·sinφ′, ρ·cosφ′) from geodetic latitude (deg) and elevation (m).
    static func observerParallaxConstants(
        latitudeDegrees latitude: Double, elevationMeters elevation: Double
    ) -> (rhoSinPhiPrime: Double, rhoCosPhiPrime: Double, sinLatitude: Double, cosLatitude: Double) {
        let u = AngleMath.toDegrees(Foundation.atan(bOverA * TrigDeg.tan(latitude)))
        let (sinLat, cosLat) = TrigDeg.sincos(latitude)
        let (sinU, cosU) = TrigDeg.sincos(u)
        let h = elevation / earthRadiusMeters
        return (bOverA * sinU + h * sinLat, cosU + h * cosLat, sinLat, cosLat)
    }

    /// Geocentric → topocentric apparent equatorial, then to geometric alt/az.
    /// Angles in degrees; distance in AU (nil = no parallax, e.g. computed points).
    static func horizontal(
        rightAscensionDegrees ra: Double,
        declinationDegrees dec: Double,
        distanceAU distance: Double?,
        localApparentSiderealTimeDegrees last: Double,
        observerLatitudeDegrees latitude: Double,
        observerElevationMeters elevation: Double
    ) -> HorizontalCoordinate {
        let hourAngle = AngleMath.normalized(degrees: last - ra)
        var topoDec = dec
        var topoHourAngle = hourAngle
        let sinLat: Double
        let cosLat: Double
        if let distance, distance > 0 {
            let parallax = observerParallaxConstants(
                latitudeDegrees: latitude, elevationMeters: elevation
            )
            let rhoSinPhiPrime = parallax.rhoSinPhiPrime
            let rhoCosPhiPrime = parallax.rhoCosPhiPrime
            sinLat = parallax.sinLatitude
            cosLat = parallax.cosLatitude
            let sinParallax = earthRadiusMeters / (distance * auMeters)
            let (sinH, cosH) = TrigDeg.sincos(hourAngle)
            let (sinDec, cosDec) = TrigDeg.sincos(dec)
            let deltaRaRad = Foundation.atan2(
                -rhoCosPhiPrime * sinParallax * sinH,
                cosDec - rhoCosPhiPrime * sinParallax * cosH
            )
            let deltaRaDeg = AngleMath.toDegrees(deltaRaRad)
            let cosDeltaRa = Foundation.cos(deltaRaRad)
            topoDec = AngleMath.toDegrees(Foundation.atan2(
                (sinDec - rhoSinPhiPrime * sinParallax) * cosDeltaRa,
                cosDec - rhoCosPhiPrime * sinParallax * cosH
            ))
            topoHourAngle = AngleMath.normalized(degrees: hourAngle - deltaRaDeg)
        } else {
            (sinLat, cosLat) = TrigDeg.sincos(latitude)
        }
        let (sinDecT, cosDecT) = TrigDeg.sincos(topoDec)
        let (sinHT, cosHT) = TrigDeg.sincos(topoHourAngle)
        let sinAlt = min(1.0, max(-1.0, sinLat * sinDecT + cosLat * cosDecT * cosHT))
        let altitude = TrigDeg.asin(sinAlt)
        // Azimuth from South, westward (Meeus 13.5), then shift to North, clockwise.
        let azSouth = Foundation.atan2(
            sinHT * cosDecT,
            cosHT * sinLat * cosDecT - sinDecT * cosLat
        )
        let azimuth = AngleMath.normalized(degrees: AngleMath.toDegrees(azSouth) + 180.0)
        return HorizontalCoordinate(altitude: altitude, azimuth: azimuth)
    }
}
