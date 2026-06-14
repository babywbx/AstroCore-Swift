@testable import AstroCore
import Foundation
import Testing

@Suite("Core Models")
struct ModelTests {
    @Test func coreEnumsExposeStableOrdering() {
        #expect(CelestialBody.allCases == [
            .sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto,
            .meanNode, .trueNode, .lilith
        ])
    }

    @Test func astroErrorStaysEquatable() {
        #expect(AstroError.extremeLatitude == .extremeLatitude)
        #expect(AstroError.unsupportedYearRange(1700) == .unsupportedYearRange(1700))
    }

    @Test func celestialPositionReservesOptionalDistance() throws {
        let reserved = CelestialPosition(body: .sun, longitude: 280.0, latitude: 0.0)
        #expect(reserved.distance == nil)

        // nil distance is omitted, so 3.0.0 payloads round-trip without the key
        let payload = try JSONEncoder().encode(reserved)
        let object = try #require(
            JSONSerialization.jsonObject(with: payload) as? [String: Any]
        )
        #expect(object["distance"] == nil)
        #expect(try JSONDecoder().decode(CelestialPosition.self, from: payload) == reserved)

        let withDistance = CelestialPosition(
            body: .moon, longitude: 120.0, latitude: 2.0, distance: 0.00257
        )
        let roundTripped = try JSONDecoder().decode(
            CelestialPosition.self,
            from: JSONEncoder().encode(withDistance)
        )
        #expect(roundTripped == withDistance)
        #expect(roundTripped.distance == 0.00257)
    }

    @Test func celestialPositionRoundTripsThroughJSON() throws {
        let position = CelestialPosition(
            body: .sun, longitude: 280.3689148247274, latitude: 0.0
        )
        let payload = try JSONEncoder().encode(position)
        let object = try #require(
            JSONSerialization.jsonObject(with: payload) as? [String: Any]
        )
        #expect(object["speed"] == nil)
        let decoded = try JSONDecoder().decode(CelestialPosition.self, from: payload)
        #expect(position == decoded)
    }

    @Test func celestialStateCarriesMotionAndDerivesPosition() throws {
        let state = CelestialState(
            body: .mars,
            longitude: 42.5,
            latitude: 1.25,
            speed: -0.13
        )
        #expect(state.isRetrograde)
        #expect(
            state.position == CelestialPosition(
                body: .mars,
                longitude: 42.5,
                latitude: 1.25
            )
        )

        let payload = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(CelestialState.self, from: payload)
        #expect(decoded == state)
    }
}
