public struct EquatorialCoordinate: Sendable, Hashable, Codable {
    /// Apparent geocentric right ascension in degrees [0, 360)
    public let rightAscension: Double
    /// Apparent geocentric declination in degrees [-90, 90]
    public let declination: Double

    public init(rightAscension: Double, declination: Double) {
        self.rightAscension = rightAscension
        self.declination = declination
    }
}

extension EquatorialCoordinate {
    /// Rotate apparent ecliptic (λ, β) by the true obliquity ε to apparent equatorial of date.
    static func from(
        eclipticLongitudeDegrees longitude: Double,
        latitudeDegrees latitude: Double,
        trueObliquityDegrees obliquity: Double
    ) -> EquatorialCoordinate {
        let (sinLon, cosLon) = TrigDeg.sincos(longitude)
        let (sinLat, cosLat) = TrigDeg.sincos(latitude)
        let (sinObl, cosObl) = TrigDeg.sincos(obliquity)
        let sinDec = min(1.0, max(-1.0, sinLat * cosObl + cosLat * sinObl * sinLon))
        let declination = TrigDeg.asin(sinDec)
        let y = cosLat * cosObl * sinLon - sinLat * sinObl
        let x = cosLat * cosLon
        let rightAscension = AngleMath.normalized(degrees: TrigDeg.atan2(y, x))
        return EquatorialCoordinate(rightAscension: rightAscension, declination: declination)
    }
}
