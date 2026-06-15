import Foundation

/// Opt-in standard atmospheric refraction. Never applied by default to horizontal coordinates.
public enum Refraction {
    /// Apparent altitude given geometric (true) altitude, both in degrees.
    /// Bennett (1982): R(arcminutes) = 1 / tan(h + 7.31 / (h + 4.4)).
    public static func apparentAltitude(geometricAltitudeDegrees altitude: Double) -> Double {
        let refractionArcminutes = 1.0 / TrigDeg.tan(altitude + 7.31 / (altitude + 4.4))
        return altitude + refractionArcminutes / 60.0
    }
}
