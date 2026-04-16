/// Full natal chart: planets + houses + angles, anchored to a moment and location.
public struct NatalChart: Sendable, Codable {
    public let positions: NatalPositions
    public let houses: HouseResult
    public let moment: CivilMoment
    public let coordinate: GeoCoordinate
}
