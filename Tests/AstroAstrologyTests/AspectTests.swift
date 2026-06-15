@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

@Suite("Aspects")
struct AspectTests {
    // MARK: - A5a model contracts

    @Test func aspectKindOrderingAndConstantsStayStable() {
        #expect(AspectKind.allCases == [
            .conjunction, .opposition, .trine, .square, .sextile,
            .quincunx, .semisextile, .semisquare, .sesquiquadrate,
            .quintile, .biquintile
        ])
        #expect(AspectKind.conjunction.rawValue == 0)
        #expect(AspectKind.sextile.rawValue == 4)
        let expectedAngles: [AspectKind: Double] = [
            .conjunction: 0, .opposition: 180, .trine: 120, .square: 90, .sextile: 60,
            .quincunx: 150, .semisextile: 30, .semisquare: 45, .sesquiquadrate: 135,
            .quintile: 72, .biquintile: 144
        ]
        for kind in AspectKind.allCases {
            #expect(kind.angleDegrees == expectedAngles[kind])
            #expect(!kind.displayName.isEmpty)
            #expect(!kind.symbol.isEmpty)
            #expect(kind.defaultOrbDegrees > 0.0)
        }
    }

    @Test func ptolemaicSetAndMajorFlagAreConsistent() {
        #expect(AspectKind.ptolemaic == [.conjunction, .opposition, .trine, .square, .sextile])
        for kind in AspectKind.allCases {
            #expect(kind.isMajor == AspectKind.ptolemaic.contains(kind))
            #expect(kind.isMajor == (kind.rawValue <= 4))
        }
    }

    @Test func defaultOrbTableMatchesContract() {
        #expect(AspectKind.conjunction.defaultOrbDegrees == 8.0)
        #expect(AspectKind.opposition.defaultOrbDegrees == 8.0)
        #expect(AspectKind.trine.defaultOrbDegrees == 8.0)
        #expect(AspectKind.square.defaultOrbDegrees == 7.0)
        #expect(AspectKind.sextile.defaultOrbDegrees == 6.0)
        #expect(AspectKind.quincunx.defaultOrbDegrees == 3.0)
        #expect(AspectKind.semisextile.defaultOrbDegrees == 2.0)
        #expect(AspectKind.semisquare.defaultOrbDegrees == 2.0)
        #expect(AspectKind.sesquiquadrate.defaultOrbDegrees == 2.0)
        #expect(AspectKind.quintile.defaultOrbDegrees == 2.0)
        #expect(AspectKind.biquintile.defaultOrbDegrees == 2.0)
    }

    @Test func defaultOrbPolicyReturnsFixedPerAspectOrb() {
        let policy = OrbPolicy.default
        for kind in AspectKind.allCases {
            #expect(policy.allowedOrb(for: kind, bodyA: .saturn, bodyB: .pluto) == kind.defaultOrbDegrees)
            #expect(
                policy.allowedOrb(for: kind, bodyA: .saturn, bodyB: .pluto)
                    == policy.allowedOrb(for: kind, bodyA: .pluto, bodyB: .saturn)
            )
        }
    }

    @Test func luminaryWeightedPolicyWidensLuminaryMajorAspects() {
        let policy = OrbPolicy.luminariesWeighted
        #expect(policy.allowedOrb(for: .conjunction, bodyA: .sun, bodyB: .moon) == 10.0)
        #expect(abs(policy.allowedOrb(for: .square, bodyA: .sun, bodyB: .saturn) - 8.75) < 1e-12)
        #expect(
            policy.allowedOrb(for: .quincunx, bodyA: .sun, bodyB: .moon)
                == AspectKind.quincunx.defaultOrbDegrees
        )
        #expect(
            policy.allowedOrb(for: .conjunction, bodyA: .sun, bodyB: .moon)
                == policy.allowedOrb(for: .conjunction, bodyA: .moon, bodyB: .sun)
        )
    }

    @Test func aspectModelDerivesSeparatingAndRoundTrips() throws {
        let aspect = Aspect(
            bodyA: .sun, bodyB: .moon, kind: .trine,
            deviation: -1.5, allowedOrb: 8.0, isApplying: true, isExact: false
        )
        #expect(aspect.isSeparating == false)
        let data = try JSONEncoder().encode(aspect)
        let decoded = try JSONDecoder().decode(Aspect.self, from: data)
        #expect(decoded == aspect)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(json.contains("deviation"))
        #expect(json.contains("allowedOrb"))
        #expect(!json.contains("\"orb\""))
        #expect(!json.contains("orbLimit"))
    }

    @Test func aspectGridLookupIsOrderIndependentAndRoundTrips() throws {
        let sunMoon = Aspect(
            bodyA: .sun, bodyB: .moon, kind: .conjunction,
            deviation: 0.5, allowedOrb: 10.0, isApplying: true, isExact: true
        )
        let grid = AspectGrid(bodies: [.sun, .moon, .mars], aspects: [sunMoon])
        #expect(grid.aspect(between: .sun, and: .moon) == sunMoon)
        #expect(grid.aspect(between: .moon, and: .sun) == sunMoon)
        #expect(grid.aspect(between: .sun, and: .mars) == nil)
        #expect(grid.aspects(of: .moon) == [sunMoon])
        #expect(grid.aspects(of: .mars).isEmpty)
        let data = try JSONEncoder().encode(grid)
        let decoded = try JSONDecoder().decode(AspectGrid.self, from: data)
        #expect(decoded == grid)
    }

    // MARK: - A5b core geometry primitives

    @Test func aspectSeparationIsSignedDeviationAndWrapsAround() {
        // Conjunction (φ=0): deviation == shortest-arc separation, sign carried.
        #expect(AstroCalculator.aspectSeparation(longitudeA: 10, longitudeB: 10, aspectAngleDegrees: 0) == 0)
        #expect(AstroCalculator.aspectSeparation(longitudeA: 10, longitudeB: 13, aspectAngleDegrees: 0) == 3)
        #expect(AstroCalculator.aspectSeparation(longitudeA: 10, longitudeB: 7, aspectAngleDegrees: 0) == 3)
        // Wrap-around across 0/360.
        #expect(AstroCalculator.aspectSeparation(longitudeA: 350, longitudeB: 10, aspectAngleDegrees: 0) == 20)
        #expect(AstroCalculator.aspectSeparation(longitudeA: 10, longitudeB: 350, aspectAngleDegrees: 0) == 20)
        // Trine (φ=120) reached from either 120 or 240 shortest arc.
        #expect(AstroCalculator.aspectSeparation(longitudeA: 0, longitudeB: 120, aspectAngleDegrees: 120) == 0)
        #expect(AstroCalculator.aspectSeparation(longitudeA: 0, longitudeB: 240, aspectAngleDegrees: 120) == 0)
        #expect(AstroCalculator.aspectSeparation(longitudeA: 0, longitudeB: 121, aspectAngleDegrees: 120) == 1)
        // Opposition (φ=180) at 180 is single-valued, deviation 0 (not double counted).
        #expect(AstroCalculator.aspectSeparation(longitudeA: 0, longitudeB: 180, aspectAngleDegrees: 180) == 0)
        #expect(AstroCalculator.aspectSeparation(longitudeA: 0, longitudeB: 175, aspectAngleDegrees: 180) == -5)
        #expect(AstroCalculator.aspectSeparation(longitudeA: 0, longitudeB: 185, aspectAngleDegrees: 180) == -5)
    }

    @Test func aspectSeparationMagnitudeIsSymmetric() {
        for (a, b) in [(350.0, 10.0), (10.0, 350.0), (0.0, 200.0), (200.0, 0.0)] {
            let ab = AstroCalculator.aspectSeparation(longitudeA: a, longitudeB: b, aspectAngleDegrees: 90)
            let ba = AstroCalculator.aspectSeparation(longitudeA: b, longitudeB: a, aspectAngleDegrees: 90)
            #expect(abs(ab) == abs(ba))
        }
    }

    @Test func closingRateSignContractProgradeApproachingAndSeparating() {
        // Prograde: B behind A and faster -> applying toward conjunction.
        let applying = AstroCalculator.aspectClosingRate(
            speedA: 1, speedB: 2, longitudeA: 10, longitudeB: 7, aspectAngleDegrees: 0
        )
        #expect(applying > 0)
        // Prograde: B ahead of A and faster -> separating from conjunction.
        let separating = AstroCalculator.aspectClosingRate(
            speedA: 1, speedB: 2, longitudeA: 10, longitudeB: 13, aspectAngleDegrees: 0
        )
        #expect(separating < 0)
    }

    @Test func closingRateRetrogradeMovesTowardAspect() {
        // B retrograde back toward A while A advances -> applying.
        let rate = AstroCalculator.aspectClosingRate(
            speedA: 1, speedB: -1, longitudeA: 10, longitudeB: 13, aspectAngleDegrees: 0
        )
        #expect(rate > 0)
    }

    @Test func closingRateIsZeroAtExactAspect() {
        #expect(
            AstroCalculator.aspectClosingRate(
                speedA: 0, speedB: 1, longitudeA: 10, longitudeB: 10, aspectAngleDegrees: 0
            ) == 0
        )
        #expect(
            AstroCalculator.aspectClosingRate(
                speedA: 0, speedB: 1, longitudeA: 0, longitudeB: 180, aspectAngleDegrees: 180
            ) == 0
        )
    }

    @Test func closingRateStaysConsistentAcrossOppositionPoint() {
        // Approaching opposition from below (B rising toward 180) -> applying.
        let beforePoint = AstroCalculator.aspectClosingRate(
            speedA: 0, speedB: 1, longitudeA: 0, longitudeB: 175, aspectAngleDegrees: 180
        )
        #expect(beforePoint > 0)
        // Just past opposition (B rising beyond 180) -> separating.
        let afterPoint = AstroCalculator.aspectClosingRate(
            speedA: 0, speedB: 1, longitudeA: 0, longitudeB: 185, aspectAngleDegrees: 180
        )
        #expect(afterPoint < 0)
    }
}
