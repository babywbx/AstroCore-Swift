import Foundation

// Router for all 12-house systems. Delegates to a system-specific implementation
// and handles polar fallback.
enum HouseEngine {
    static func compute(
        for moment: CivilMoment,
        coordinate: GeoCoordinate,
        system: HouseSystem,
        polarFallback: PolarFallback
    ) throws(AstroError) -> HouseResult {
        let angles = try AnglesEngine.compute(for: moment, coordinate: coordinate)
        let lastDeg = moment.localApparentSiderealTime(longitude: coordinate.longitude)

        let context = Context(
            moment: moment,
            coordinate: coordinate,
            angles: angles,
            lastDegrees: lastDeg,
            obliquityDegrees: moment.trueObliquity
        )

        // Polar fallback: systems with hasPolarLimit fall back above the polar
        // circle. The threshold matches Swiss Ephemeris behavior.
        if system.hasPolarLimit && abs(coordinate.latitude) > 66.0 {
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
                angles: angles,
                julianDayUT: moment.julianDayUT
            )
        }

        let cusps = try dispatch(system, context: context)
        return buildResult(
            requested: system,
            resolved: system,
            cusps: cusps,
            angles: angles,
            julianDayUT: moment.julianDayUT
        )
    }

    /// Shared inputs handed to every system implementation.
    struct Context {
        let moment: CivilMoment
        let coordinate: GeoCoordinate
        let angles: Angles
        let lastDegrees: Double       // ARMC / LAST in degrees
        let obliquityDegrees: Double  // True obliquity
    }

    private static func dispatch(
        _ system: HouseSystem,
        context: Context
    ) throws(AstroError) -> [Double] {
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

        case .placidus, .koch, .alcabitius,
             .sunshineTreindl, .sunshineMakransky,
             .campanus, .regiomontanus, .morinus, .topocentric,
             .krusinski, .apc,
             .horizontal, .meridian, .axialRotation, .carter,
             .pullenSD, .pullenSR:
            throw .houseSystemNotYetImplemented(system: system)
        }
    }

    private static func resolveFallback(
        requested: HouseSystem,
        fallback: PolarFallback,
        latitude: Double
    ) throws(AstroError) -> HouseSystem {
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
        angles: Angles,
        julianDayUT: Double
    ) -> HouseResult {
        precondition(cusps.count == 12, "House system must produce 12 cusps")
        let wrapped = cusps.enumerated().map { index, longitude in
            let normalized = AngleMath.normalized(degrees: longitude)
            let details = ZodiacMapper.details(forNormalizedLongitude: normalized)
            return HouseCusp(
                number: index + 1,
                eclipticLongitude: normalized,
                sign: details.sign,
                degreeInSign: details.degreeInSign
            )
        }
        return HouseResult(
            requestedSystem: requested,
            resolvedSystem: resolved,
            cusps: wrapped,
            angles: angles,
            julianDayUT: julianDayUT
        )
    }
}
