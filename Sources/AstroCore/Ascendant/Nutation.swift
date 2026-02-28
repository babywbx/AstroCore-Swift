import Foundation

// Nutation — IAU 1980, 63 terms
// Implemented in Phase 2
enum Nutation {
    struct Result: Sendable {
        let longitude: Double // Δψ in arcseconds
        let obliquity: Double // Δε in arcseconds
    }

    // Placeholder — full implementation in Phase 2
    static func compute(julianCenturiesTT t: Double) -> Result {
        fatalError("Phase 2: Not yet implemented")
    }
}
