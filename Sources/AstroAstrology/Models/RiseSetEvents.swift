import AstroCore

/// A diurnal event time. `julianDayUT` is authoritative and survives Codable round-trips;
/// `civilMoment` is the integer-second civil rendering in the requested time zone.
public struct EventInstant: Sendable, Equatable, Codable {
    public let julianDayUT: Double
    public let civilMoment: CivilMoment

    public init(julianDayUT: Double, civilMoment: CivilMoment) {
        self.julianDayUT = julianDayUT
        self.civilMoment = civilMoment
    }
}

/// Rise / set / culmination events for a body over one civil day at a location.
public struct RiseSetEvents: Sendable, Equatable, Codable {
    public let body: CelestialBody
    public let rise: EventInstant?
    public let set: EventInstant?
    public let upperTransit: EventInstant?
    public let lowerTransit: EventInstant?
    /// Never sets that day (always above the horizon).
    public let circumpolar: Bool
    /// Never rises that day (always below the horizon).
    public let neverRises: Bool

    public init(
        body: CelestialBody,
        rise: EventInstant?,
        set: EventInstant?,
        upperTransit: EventInstant?,
        lowerTransit: EventInstant?,
        circumpolar: Bool,
        neverRises: Bool
    ) {
        self.body = body
        self.rise = rise
        self.set = set
        self.upperTransit = upperTransit
        self.lowerTransit = lowerTransit
        self.circumpolar = circumpolar
        self.neverRises = neverRises
    }
}
