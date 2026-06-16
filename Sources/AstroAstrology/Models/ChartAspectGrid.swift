import AstroCore

/// Aspects among bodies and chart angles. Additive to the body-only `AspectGrid`: it carries
/// body-body, body-angle, and angle-angle aspects with participants in canonical order.
public struct ChartAspectGrid: Sendable, Equatable, Codable {
    /// Participants in canonical order (bodies by CaseIterable, then angles).
    public let participants: [AspectParticipant]
    public let aspects: [ChartAspect]

    public init(participants: [AspectParticipant], aspects: [ChartAspect]) {
        self.participants = participants
        self.aspects = aspects
    }

    /// Aspect between a pair regardless of argument order.
    public func aspect(between a: AspectParticipant, and b: AspectParticipant) -> ChartAspect? {
        aspects.first {
            ($0.a == a && $0.b == b) || ($0.a == b && $0.b == a)
        }
    }
}
