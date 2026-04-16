import Foundation

// Porphyry houses: trisect each ecliptic quadrant between the four angles.
// Oldest quadrant system (3rd century CE Porphyry of Tyre). Produces houses
// of varying sizes at non-equatorial latitudes but needs only the angles —
// no semi-arc math.
enum PorphyryHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        porphyryCusps(angles: context.angles)
    }

    /// Shared core used by both Porphyry and Sripati.
    static func porphyryCusps(angles: Angles) -> [Double] {
        let asc = angles.ascendant
        let mc = angles.midheaven
        let dsc = angles.descendant
        let ic = angles.imumCoeli

        // Forward arcs around the ecliptic (always positive, typically 60°-120°).
        let arcMCtoASC = AngleMath.normalized(degrees: asc - mc)
        let arcASCtoIC = AngleMath.normalized(degrees: ic - asc)
        let arcICtoDSC = AngleMath.normalized(degrees: dsc - ic)
        let arcDSCtoMC = AngleMath.normalized(degrees: mc - dsc)

        var cusps = [Double](repeating: 0, count: 12)
        cusps[0] = asc                                      // House 1
        cusps[1] = asc + arcASCtoIC / 3.0                   // House 2
        cusps[2] = asc + arcASCtoIC * 2.0 / 3.0             // House 3
        cusps[3] = ic                                       // House 4
        cusps[4] = ic + arcICtoDSC / 3.0                    // House 5
        cusps[5] = ic + arcICtoDSC * 2.0 / 3.0              // House 6
        cusps[6] = dsc                                      // House 7
        cusps[7] = dsc + arcDSCtoMC / 3.0                   // House 8
        cusps[8] = dsc + arcDSCtoMC * 2.0 / 3.0             // House 9
        cusps[9] = mc                                       // House 10
        cusps[10] = mc + arcMCtoASC / 3.0                   // House 11
        cusps[11] = mc + arcMCtoASC * 2.0 / 3.0             // House 12
        return cusps
    }
}
