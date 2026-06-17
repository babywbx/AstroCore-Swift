@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

@Suite("Aspect Baselines")
struct AspectBaselineTests {
    private struct AspectIdentity: Hashable, CustomStringConvertible {
        let bodyA: CelestialBody
        let bodyB: CelestialBody
        let kind: AspectKind

        var description: String {
            "\(bodyA)-\(bodyB) \(kind.displayName)"
        }
    }

    private struct ReferenceAspect {
        let identity: AspectIdentity
        let deviation: Double
    }

    private static let mainBodies: [CelestialBody] =
        [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto]

    private static var enabled: Bool {
        ProcessInfo.processInfo.environment["ASTROCORE_ENABLE_BASELINE_VERIFICATION"] == "1"
    }

    @Test func exactMomentLandsOnRealAspectPerReference() throws {
        guard Self.enabled else { return }
        let seed = try AstroCalculator.julianDayUT(
            for: CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        )
        // Sun-Moon conjunction (phi = 0).
        let tStarUT = try #require(
            AstroCalculator.exactAspectJulianDayUT(
                of: .sun, and: .moon, aspectAngleDegrees: 0, nearJulianDayUT: seed
            )
        )
        let reference = try AstrologyTestSupport.referenceBodyLongitudes(
            julianDaysUT: [tStarUT], bodies: [.sun, .moon]
        )
        let sun = try #require(reference.first?[.sun])
        let moon = try #require(reference.first?[.moon])
        let separation = abs(AstroCalculator.aspectSeparation(
            longitudeA: sun, longitudeB: moon, aspectAngleDegrees: 0
        ))
        #expect(separation < 1e-2, "reference separation at t* = \(separation)°")
    }

    @Test func gridOrbsAgreeWithReferenceLongitudes() throws {
        guard Self.enabled else { return }
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30, timeZoneIdentifier: "America/New_York"
        )
        let jdUT = AstroCalculator.julianDayUT(for: moment)
        let grid = try AstrologyCalculator.aspects(
            for: moment, bodies: Set(Self.mainBodies), aspectKinds: Set(AspectKind.allCases)
        )
        let reference = try AstrologyTestSupport.referenceBodyLongitudes(
            julianDaysUT: [jdUT], bodies: Self.mainBodies
        )
        let longitudes = try #require(reference.first)
        let expected = try Self.expectedAspects(from: longitudes, bodies: Self.mainBodies)
        let expectedKeys = Set(expected.keys)
        let actualKeys = Set(grid.aspects.map {
            AspectIdentity(bodyA: $0.bodyA, bodyB: $0.bodyB, kind: $0.kind)
        })

        #expect(
            actualKeys.count == grid.aspects.count,
            "aspect grid contains duplicate aspect identities"
        )
        #expect(
            grid.aspects.count == expected.count,
            "detected \(grid.aspects.count) aspects, expected \(expected.count)"
        )
        #expect(
            actualKeys == expectedKeys,
            """
            aspect set mismatch; missing: \(Self.describe(expectedKeys.subtracting(actualKeys))); \
            unexpected: \(Self.describe(actualKeys.subtracting(expectedKeys)))
            """
        )

        for aspect in grid.aspects {
            let identity = AspectIdentity(bodyA: aspect.bodyA, bodyB: aspect.bodyB, kind: aspect.kind)
            let referenceAspect = try #require(
                expected[identity],
                "unexpected detected aspect \(identity)"
            )
            #expect(
                abs(aspect.deviation - referenceAspect.deviation) < 1e-2,
                "\(identity): mine \(aspect.deviation) vs ref \(referenceAspect.deviation)"
            )
        }
    }

    private static func expectedAspects(
        from longitudes: [CelestialBody: Double],
        bodies: [CelestialBody]
    ) throws -> [AspectIdentity: ReferenceAspect] {
        var expected: [AspectIdentity: ReferenceAspect] = [:]
        for indexA in 0..<bodies.count {
            for indexB in (indexA + 1)..<bodies.count {
                let bodyA = bodies[indexA]
                let bodyB = bodies[indexB]
                let longitudeA = try #require(longitudes[bodyA])
                let longitudeB = try #require(longitudes[bodyB])
                var best: ReferenceAspect?
                for kind in AspectKind.allCases {
                    let deviation = AstroCalculator.aspectSeparation(
                        longitudeA: longitudeA,
                        longitudeB: longitudeB,
                        aspectAngleDegrees: kind.angleDegrees
                    )
                    let allowedOrb = OrbPolicy.default.allowedOrb(for: kind, bodyA: bodyA, bodyB: bodyB)
                    guard abs(deviation) <= allowedOrb else { continue }
                    if let current = best, abs(current.deviation) <= abs(deviation) { continue }
                    let identity = AspectIdentity(bodyA: bodyA, bodyB: bodyB, kind: kind)
                    best = ReferenceAspect(identity: identity, deviation: deviation)
                }
                if let best {
                    expected[best.identity] = best
                }
            }
        }
        return expected
    }

    private static func describe(_ identities: Set<AspectIdentity>) -> String {
        identities
            .map(\.description)
            .sorted()
            .joined(separator: ", ")
    }
}
