import Foundation

/// Opt-in standard atmospheric refraction. Never applied by default to horizontal coordinates.
public enum Refraction {
    /// Apparent altitude given geometric (true) altitude, both in degrees.
    /// Bennett (1982): R(arcminutes) = 1 / tan(h + 7.31 / (h + 4.4)).
    /// Valid for the visible sky; below ~-1° the model is undefined (singular near
    /// h = -4.4°), so the geometric altitude is returned unchanged there.
    public static func apparentAltitude(geometricAltitudeDegrees altitude: Double) -> Double {
        guard altitude > -1.0 else { return altitude }
        let refractionArcminutes = 1.0 / TrigDeg.tan(altitude + 7.31 / (altitude + 4.4))
        return altitude + refractionArcminutes / 60.0
    }
}
