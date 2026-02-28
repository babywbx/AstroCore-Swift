import Foundation

// VSOP87D evaluation engine
// Implemented in Phase 3
enum VSOP87D {
    struct SphericalPosition: Sendable {
        let longitude: Double // radians
        let latitude: Double  // radians
        let radius: Double    // AU
    }
}
