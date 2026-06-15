import Foundation

extension AstroCalculator {
    /// Signed deviation = shortest-arc separation − aspect angle (deg), range [-180, 180]; |value| is the orb gap.
    public static func aspectSeparation(
        longitudeA: Double,
        longitudeB: Double,
        aspectAngleDegrees: Double
    ) -> Double {
        let delta = wrappedDelta(longitudeB - longitudeA)
        return abs(delta) - aspectAngleDegrees
    }

    /// Continuous closing rate (deg/day) of the (A,B) pair toward the aspect.
    /// SIGN CONTRACT: closingRate > 0 ⟺ applying (gap shrinking);
    ///                closingRate < 0 ⟺ separating; == 0 ⟺ exact / stationary.
    /// The "+ / −" here is unrelated to isRetrograde's "negative = retrograde".
    public static func aspectClosingRate(
        speedA: Double,
        speedB: Double,
        longitudeA: Double,
        longitudeB: Double,
        aspectAngleDegrees: Double
    ) -> Double {
        let delta = wrappedDelta(longitudeB - longitudeA)
        let separation = abs(delta)
        let relSpeed = speedB - speedA
        return -signum(separation - aspectAngleDegrees) * signum(delta) * relSpeed
    }

    /// Fold a raw degree difference into (-180, 180] using the canonical normalizer.
    @inline(__always)
    static func wrappedDelta(_ raw: Double) -> Double {
        let n = AngleMath.normalized(degrees: raw)
        return n > 180.0 ? n - 360.0 : n
    }

    @inline(__always)
    static func signum(_ value: Double) -> Double {
        value > 0.0 ? 1.0 : (value < 0.0 ? -1.0 : 0.0)
    }

    /// Julian Day (TT) of the exact aspect nearest the seed, found by TT-domain root-solving
    /// of g(t) = wrap180((λ_B − λ_A) − target) = 0; nil when none lies in the window.
    public static func exactAspectJulianDayTT(
        of bodyA: CelestialBody,
        and bodyB: CelestialBody,
        aspectAngleDegrees phi: Double,
        nearJulianDayTT jd: Double,
        searchWindowDays window: Double = 60.0
    ) -> Double? {
        let targets: [Double] = (phi < 1e-9 || phi > 180.0 - 1e-9) ? [phi] : [phi, -phi]
        var nearest: Double?
        var nearestDistance = Double.infinity
        for target in targets {
            for root in aspectRoots(bodyA, bodyB, target: target, near: jd, window: window) {
                let distance = abs(root - jd)
                if distance < nearestDistance {
                    nearestDistance = distance
                    nearest = root
                }
            }
        }
        return nearest
    }

    /// UT variant. Root-solving still happens entirely in TT; the input UT JD is converted to
    /// TT, solved, then the TT result is inverted back to UT (jdUT = jdTT − ΔT(jdUT)/86400).
    public static func exactAspectJulianDayUT(
        of bodyA: CelestialBody,
        and bodyB: CelestialBody,
        aspectAngleDegrees phi: Double,
        nearJulianDayUT jd: Double,
        searchWindowDays window: Double = 60.0
    ) -> Double? {
        let seedTT = jd + deltaTSeconds(julianDayUT: jd) / 86400.0
        guard let starTT = exactAspectJulianDayTT(
            of: bodyA, and: bodyB, aspectAngleDegrees: phi,
            nearJulianDayTT: seedTT, searchWindowDays: window
        ) else { return nil }
        var jdUT = starTT
        for _ in 0..<8 {
            let next = starTT - deltaTSeconds(julianDayUT: jdUT) / 86400.0
            if abs(next - jdUT) < 1e-9 {
                jdUT = next
                break
            }
            jdUT = next
        }
        return jdUT
    }

    // MARK: - Root-solving internals (TT domain)

    private static let aspectSamplingArcDegrees = 4.0
    private static let aspectMinStepDays = 0.05
    private static let aspectMaxSamplesDivisor = 16.0
    private static let aspectRootTolDegrees = 1e-8
    private static let aspectRootTolDays = 1e-9

    /// Signed continuous residual; zero when (λ_B − λ_A) ≡ target (mod 360).
    private static func aspectResidual(
        _ bodyA: CelestialBody, _ bodyB: CelestialBody, target: Double, jdTT: Double
    ) -> Double {
        let la = eclipticLongitude(of: bodyA, julianDayTT: jdTT)
        let lb = eclipticLongitude(of: bodyB, julianDayTT: jdTT)
        return wrappedDelta(lb - la - target)
    }

    /// d(residual)/dt = relative longitude speed; the true local slope (wrap180 is locally identity).
    private static func aspectResidualSlope(
        _ bodyA: CelestialBody, _ bodyB: CelestialBody, jdTT: Double
    ) -> Double {
        longitudeSpeed(of: bodyB, julianDayTT: jdTT) - longitudeSpeed(of: bodyA, julianDayTT: jdTT)
    }

    /// All TT roots of the residual in [jd − window, jd + window] for one target angle.
    private static func aspectRoots(
        _ bodyA: CelestialBody, _ bodyB: CelestialBody,
        target: Double, near jd: Double, window: Double
    ) -> [Double] {
        let relSpeed = abs(aspectResidualSlope(bodyA, bodyB, jdTT: jd))
        let rawStep = aspectSamplingArcDegrees / (2.0 * max(relSpeed, 1e-6))
        let step = min(max(rawStep, aspectMinStepDays), 2.0 * window / aspectMaxSamplesDivisor)
        let start = jd - window
        let end = jd + window

        var roots: [Double] = []
        var previousT = start
        var previousG = aspectResidual(bodyA, bodyB, target: target, jdTT: previousT)
        if abs(previousG) < aspectRootTolDegrees { roots.append(previousT) }

        var t = start + step
        while t <= end + 0.5 * step {
            let clamped = min(t, end)
            let g = aspectResidual(bodyA, bodyB, target: target, jdTT: clamped)
            let crossesZero = (previousG < 0) != (g < 0)
            let notWrapJump = abs(g - previousG) < 180.0
            if abs(g) < aspectRootTolDegrees {
                roots.append(clamped)
            } else if previousG != 0, crossesZero, notWrapJump {
                roots.append(refineAspectRoot(
                    bodyA, bodyB, target: target,
                    low: previousT, high: clamped, gLow: previousG, gHigh: g
                ))
            }
            previousT = clamped
            previousG = g
            t += step
        }
        return dedupedRoots(roots)
    }

    /// Safeguarded Newton-bisection on a sign-changing bracket.
    private static func refineAspectRoot(
        _ bodyA: CelestialBody, _ bodyB: CelestialBody, target: Double,
        low: Double, high: Double, gLow: Double, gHigh: Double
    ) -> Double {
        var xLow = gLow < 0 ? low : high
        var xHigh = gLow < 0 ? high : low
        var root = 0.5 * (low + high)
        var stepOld = abs(high - low)
        var stepCurrent = stepOld
        var g = aspectResidual(bodyA, bodyB, target: target, jdTT: root)
        var slope = aspectResidualSlope(bodyA, bodyB, jdTT: root)

        for _ in 0..<60 {
            let newtonOutOfRange =
                ((root - xHigh) * slope - g) * ((root - xLow) * slope - g) > 0
            let slowConvergence = abs(2.0 * g) > abs(stepOld * slope)
            if newtonOutOfRange || slowConvergence {
                stepOld = stepCurrent
                stepCurrent = 0.5 * (xHigh - xLow)
                root = xLow + stepCurrent
                if xLow == root { return root }
            } else {
                stepOld = stepCurrent
                stepCurrent = g / slope
                let previous = root
                root -= stepCurrent
                if previous == root { return root }
            }
            if abs(stepCurrent) < aspectRootTolDays { return root }
            g = aspectResidual(bodyA, bodyB, target: target, jdTT: root)
            slope = aspectResidualSlope(bodyA, bodyB, jdTT: root)
            if g < 0 { xLow = root } else { xHigh = root }
        }
        return root
    }

    /// Merge roots that collapse to the same crossing (e.g. ±phi targets at conjunction/opposition).
    private static func dedupedRoots(_ roots: [Double]) -> [Double] {
        guard roots.count > 1 else { return roots }
        let sorted = roots.sorted()
        var unique: [Double] = [sorted[0]]
        for value in sorted.dropFirst() where abs(value - (unique.last ?? value)) > 1e-3 {
            unique.append(value)
        }
        return unique
    }
}
