import AstroCore
import Foundation

struct EquatorialVector {
    let x: Double
    let y: Double
    let z: Double

    init(rightAscension: Double, declination: Double) {
        let sinRightAscension = TrigDeg.sin(rightAscension)
        let cosRightAscension = TrigDeg.cos(rightAscension)
        let sinDeclination = TrigDeg.sin(declination)
        let cosDeclination = TrigDeg.cos(declination)

        self.x = cosDeclination * cosRightAscension
        self.y = cosDeclination * sinRightAscension
        self.z = sinDeclination
    }

    static func horizonPoint(
        azimuth: Double,
        lastDegrees: Double,
        latitudeDegrees: Double
    ) -> EquatorialVector {
        let sinLatitude = TrigDeg.sin(latitudeDegrees)
        let cosLatitude = TrigDeg.cos(latitudeDegrees)
        let sinAzimuth = TrigDeg.sin(azimuth)
        let cosAzimuth = TrigDeg.cos(azimuth)
        let sinDeclination = cosLatitude * cosAzimuth
        let declination = TrigDeg.asin(max(-1.0, min(1.0, sinDeclination)))
        let hourAngle = TrigDeg.atan2(-sinAzimuth, -sinLatitude * cosAzimuth)
        let rightAscension = AngleMath.normalized(degrees: lastDegrees - hourAngle)
        return EquatorialVector(
            rightAscension: rightAscension,
            declination: declination
        )
    }

    func cross(_ other: EquatorialVector) -> EquatorialVector {
        EquatorialVector(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }

    func eclipticIntersectionLongitude(obliquityDegrees: Double) -> Double {
        AngleMath.normalized(
            degrees: TrigDeg.atan2(
                -x,
                y * TrigDeg.cos(obliquityDegrees) + z * TrigDeg.sin(obliquityDegrees)
            )
        )
    }

    private init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}
