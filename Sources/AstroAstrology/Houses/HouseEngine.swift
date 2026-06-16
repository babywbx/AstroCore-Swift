import AstroCore
import Foundation

/// Router for all 12-house systems. Delegates to a system-specific implementation
/// and handles polar fallback.
enum HouseEngine {
    static func compute(
        for moment: CivilMoment,
        coordinate: GeoCoordinate,
        system: HouseSystem,
        polarFallback: PolarFallback
    ) throws(AstrologyError) -> HouseResult {
        let angles = try AnglesEngine.compute(for: moment, coordinate: coordinate)
        let lastDeg = moment.localApparentSiderealTime(longitude: coordinate.longitude)

        let context = Context(
            moment: moment,
            coordinate: coordinate,
            angles: angles,
            lastDegrees: lastDeg,
            obliquityDegrees: moment.trueObliquity
        )

        // Polar fallback: semi-arc systems become undefined only once the
        // observer crosses the ecliptic polar circle, i.e. |φ| > 90° − ε.
        // Using the moment's true obliquity avoids prematurely falling back in
        // the ~66.0°...66.56° band where the ecliptic is still fully rising/setting.
        let polarCircleLatitude = 90.0 - abs(context.obliquityDegrees)
        if system.hasPolarLimit && abs(coordinate.latitude) > polarCircleLatitude {
            let resolved = try resolveFallback(
                requested: system,
                fallback: polarFallback,
                latitude: coordinate.latitude
            )
            let cusps = try dispatch(resolved, context: context)
            return buildResult(
                requested: system,
                resolved: resolved,
                cusps: cusps,
                angles: angles
            )
        }

        let cusps = try dispatch(system, context: context)
        return buildResult(
            requested: system,
            resolved: system,
            cusps: cusps,
            angles: angles
        )
    }

    /// Shared inputs handed to every system implementation.
    struct Context {
        let moment: CivilMoment
        let coordinate: GeoCoordinate
        let angles: Angles
        let lastDegrees: Double // ARMC / LAST in degrees
        let obliquityDegrees: Double // True obliquity
    }

    private static func dispatch(
        _ system: HouseSystem,
        context: Context
    ) throws(AstrologyError) -> [Double] {
        switch system {
        case .wholeSign:
            WholeSignHouses.cusps(context: context)
        case .equalASC:
            EqualHouses.cuspsFromAscendant(context: context)
        case .equalMC:
            EqualHouses.cuspsFromMidheaven(context: context)
        case .vehlow:
            EqualHouses.cuspsVehlow(context: context)
        case .porphyry:
            PorphyryHouses.cusps(context: context)
        case .sripati:
            SripatiHouses.cusps(context: context)
        case .placidus:
            PlacidusHouses.cusps(context: context)
        case .koch:
            KochHouses.cusps(context: context)
        case .regiomontanus:
            RegiomontanusHouses.cusps(context: context)
        case .campanus:
            CampanusHouses.cusps(context: context)
        case .alcabitius:
            AlcabitiusHouses.cusps(context: context)
        case .topocentric:
            TopocentricHouses.cusps(context: context)
        case .horizontal:
            HorizontalHouses.cusps(context: context)
        case .morinus:
            MorinusHouses.cusps(context: context)
        case .meridian:
            MeridianHouses.cusps(context: context)
        case .carter:
            CarterHouses.cusps(context: context)
        }
    }

    private static func resolveFallback(
        requested: HouseSystem,
        fallback: PolarFallback,
        latitude: Double
    ) throws(AstrologyError) -> HouseSystem {
        switch fallback {
        case .porphyry: .porphyry
        case .equalASC: .equalASC
        case .wholeSign: .wholeSign
        case .error:
            throw .houseSystemUndefinedAtLatitude(
                system: requested,
                latitude: latitude
            )
        }
    }

    private static func buildResult(
        requested: HouseSystem,
        resolved: HouseSystem,
        cusps: [Double],
        angles: Angles
    ) -> HouseResult {
        precondition(cusps.count == 12, "House system must produce 12 cusps")
        var wrapped: [HouseCusp] = []
        wrapped.reserveCapacity(cusps.count)
        for (index, longitude) in cusps.enumerated() {
            let normalized = AngleMath.normalized(degrees: longitude)
            let details = ZodiacMapper.details(forNormalizedLongitude: normalized)
            wrapped.append(HouseCusp(
                number: index + 1,
                eclipticLongitude: normalized,
                sign: details.sign,
                degreeInSign: details.degreeInSign
            ))
        }
        return HouseResult(
            requestedSystem: requested,
            resolvedSystem: resolved,
            cusps: wrapped,
            angles: angles
        )
    }
}
