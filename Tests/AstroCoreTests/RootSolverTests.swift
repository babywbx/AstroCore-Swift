@testable import AstroCore
import Foundation
import Testing

@Suite("Root Solver")
struct RootSolverTests {
    /// Fold a raw degree value into (-180, 180], matching the aspect residual's wrap.
    private static func wrapped(_ raw: Double) -> Double {
        let n = AngleMath.normalized(degrees: raw)
        return n > 180.0 ? n - 360.0 : n
    }

    @Test func nearestRootFindsClosestRootOfSine() {
        let tuning = RootSolver.Tuning(step: 0.1, valueTolerance: 1e-10, stepTolerance: 1e-12)
        let root = RootSolver.nearestRoot(
            near: 3.0,
            window: 5.0,
            tuning: tuning,
            value: { sin($0) },
            slope: { cos($0) }
        )
        #expect(root != nil)
        #expect(abs((root ?? .nan) - Double.pi) < 1e-8)
    }

    @Test func nearestRootSolvesQuadraticOnBothSides() {
        let tuning = RootSolver.Tuning(step: 0.25, valueTolerance: 1e-12, stepTolerance: 1e-12)
        let value: (Double) -> Double = { $0 * $0 - $0 - 2.0 } // (x - 2)(x + 1)
        let slope: (Double) -> Double = { 2.0 * $0 - 1.0 }
        let high = RootSolver.nearestRoot(near: 1.4, window: 6.0, tuning: tuning, value: value, slope: slope)
        let low = RootSolver.nearestRoot(near: -0.4, window: 6.0, tuning: tuning, value: value, slope: slope)
        #expect(abs((high ?? .nan) - 2.0) < 1e-8)
        #expect(abs((low ?? .nan) - -1.0) < 1e-8)
    }

    @Test func nearestRootReturnsNilWhenNoRootInWindow() {
        let tuning = RootSolver.Tuning(step: 0.1, valueTolerance: 1e-12, stepTolerance: 1e-12)
        let root = RootSolver.nearestRoot(
            near: 0.0,
            window: 5.0,
            tuning: tuning,
            value: { $0 * $0 + 1.0 },
            slope: { 2.0 * $0 }
        )
        #expect(root == nil)
    }

    @Test func rootsEnumeratesAllCrossingsInInterval() {
        let tuning = RootSolver.Tuning(step: 0.3, valueTolerance: 1e-10, stepTolerance: 1e-9)
        let roots = RootSolver.roots(
            from: -0.5,
            through: 7.0,
            tuning: tuning,
            value: { sin($0) },
            slope: { cos($0) }
        )
        #expect(roots.count == 3)
        let expected = [0.0, Double.pi, 2.0 * Double.pi]
        for (found, want) in zip(roots, expected) {
            #expect(abs(found - want) < 1e-7)
        }
    }

    @Test func wrapGuardRejectsAngularDiscontinuities() {
        let value: (Double) -> Double = { Self.wrapped($0) }
        let slope: (Double) -> Double = { _ in 1.0 }

        let guarded = RootSolver.Tuning(
            step: 5.0, valueTolerance: 1e-9, stepTolerance: 1e-9, wrapGuardDegrees: 180.0
        )
        let guardedRoots = RootSolver.roots(
            from: -10.0, through: 370.0, tuning: guarded, value: value, slope: slope
        )
        #expect(guardedRoots.count == 2) // real zeros at 0 and 360 only
        #expect(guardedRoots.allSatisfy { abs(Self.wrapped($0)) < 1e-6 })

        let unguarded = RootSolver.Tuning(step: 5.0, valueTolerance: 1e-9, stepTolerance: 1e-9)
        let unguardedRoots = RootSolver.roots(
            from: -10.0, through: 370.0, tuning: unguarded, value: value, slope: slope
        )
        #expect(unguardedRoots.count > guardedRoots.count) // wrap at 180 mistaken for a crossing
    }

    @Test func refineFallsBackToBisectionWhenSlopeUnusable() {
        let tuning = RootSolver.Tuning(step: 1.0, valueTolerance: 1e-12, stepTolerance: 1e-12)
        let root = RootSolver.nearestRoot(
            near: 0.0,
            window: 10.0,
            tuning: tuning,
            value: { $0 - 3.3 },
            slope: { _ in 0.0 }
        )
        #expect(abs((root ?? .nan) - 3.3) < 1e-6)
    }
}
