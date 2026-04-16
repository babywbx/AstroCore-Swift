/// Result of a house computation.
///
/// `requestedSystem` is what the caller asked for; `resolvedSystem` is what was
/// actually computed. They differ when a polar fallback fired.
public struct HouseResult: Sendable, Hashable, Codable {
    public let requestedSystem: HouseSystem
    public let resolvedSystem: HouseSystem
    /// Always 12 cusps, indexed as `cusps[0]` = house 1.
    public let cusps: [HouseCusp]
    public let angles: Angles
    public let julianDayUT: Double

    /// True when the request was satisfied without fallback.
    public var usedRequestedSystem: Bool { requestedSystem == resolvedSystem }
}
