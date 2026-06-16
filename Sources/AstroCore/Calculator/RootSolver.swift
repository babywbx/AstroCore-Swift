import Foundation

/// A general 1-D root finder, factored out of the aspect engine. It brackets sign changes by
/// expanding outward from a seed (or scanning a closed interval) and refines each bracket with a
/// safeguarded Newton-bisection (rtsafe). Callers supply `value` and an analytic/semi-analytic
/// `slope`; `Tuning.wrapGuardDegrees` rejects brackets whose endpoints differ by at least that many
/// degrees — for angular residuals that jump ±360 at wrap points — or `nil` to disable the guard.
enum RootSolver {
    /// Solver knobs: the sampling `step`, the value/step convergence tolerances, and the optional
    /// wrap guard. Bundled so the solver and its helpers stay within a small parameter count.
    struct Tuning {
        let step: Double
        let valueTolerance: Double
        let stepTolerance: Double
        let wrapGuardDegrees: Double?

        init(
            step: Double,
            valueTolerance: Double,
            stepTolerance: Double,
            wrapGuardDegrees: Double? = nil
        ) {
            self.step = step
            self.valueTolerance = valueTolerance
            self.stepTolerance = stepTolerance
            self.wrapGuardDegrees = wrapGuardDegrees
        }
    }

    /// Nearest root of `value` to `seed` within ±`window`. Expands the search symmetrically outward
    /// and stops once no closer root can remain on either side. Returns nil when none lies in range.
    static func nearestRoot(
        near seed: Double,
        window: Double,
        tuning: Tuning,
        value: (Double) -> Double,
        slope: (Double) -> Double
    ) -> Double? {
        let seedValue = value(seed)
        if abs(seedValue) < tuning.valueTolerance { return seed }

        var best: Double?
        var bestDistance = Double.infinity
        let forwardLimit = seed + window
        let backwardLimit = seed - window
        var forwardT = seed, forwardValue = seedValue, forwardActive = true
        var backwardT = seed, backwardValue = seedValue, backwardActive = true
        var shell = 1

        while forwardActive || backwardActive {
            if forwardActive {
                let next = min(forwardT + tuning.step, forwardLimit)
                let g = value(next)
                if let root = bracketRoot(
                    low: forwardT, high: next, gLow: forwardValue, gHigh: g,
                    tuning: tuning, value: value, slope: slope
                ), abs(root - seed) < bestDistance {
                    bestDistance = abs(root - seed)
                    best = root
                }
                if next >= forwardLimit { forwardActive = false }
                forwardT = next
                forwardValue = g
            }
            if backwardActive {
                let next = max(backwardT - tuning.step, backwardLimit)
                let g = value(next)
                if let root = bracketRoot(
                    low: next, high: backwardT, gLow: g, gHigh: backwardValue,
                    tuning: tuning, value: value, slope: slope
                ), abs(root - seed) < bestDistance {
                    bestDistance = abs(root - seed)
                    best = root
                }
                if next <= backwardLimit { backwardActive = false }
                backwardT = next
                backwardValue = g
            }
            if best != nil, Double(shell) * tuning.step >= bestDistance { break }
            shell += 1
        }
        return best
    }

    /// All roots of `value` in the closed interval `[start, end]`, scanned forward with the same
    /// bracket + refinement. Roots within `stepTolerance` of the previous one are de-duplicated so a
    /// crossing landing on a shared sample boundary is reported once. The primitive for event/
    /// interval enumeration, where `nearestRoot` would repeatedly re-find the same crossing.
    static func roots(
        from start: Double,
        through end: Double,
        tuning: Tuning,
        value: (Double) -> Double,
        slope: (Double) -> Double
    ) -> [Double] {
        guard end > start, tuning.step > 0 else { return [] }
        var found: [Double] = []
        var lowT = start
        var lowValue = value(start)

        while lowT < end {
            let highT = min(lowT + tuning.step, end)
            let highValue = value(highT)
            if let root = bracketRoot(
                low: lowT, high: highT, gLow: lowValue, gHigh: highValue,
                tuning: tuning, value: value, slope: slope
            ) {
                if let last = found.last {
                    if abs(root - last) > tuning.stepTolerance { found.append(root) }
                } else {
                    found.append(root)
                }
            }
            if highT >= end { break }
            lowT = highT
            lowValue = highValue
        }
        return found
    }

    /// A refined root inside one sampling interval, or nil when no real (non-wrap) crossing sits
    /// there. An endpoint already at the value tolerance is returned directly.
    private static func bracketRoot(
        low: Double, high: Double, gLow: Double, gHigh: Double, tuning: Tuning,
        value: (Double) -> Double, slope: (Double) -> Double
    ) -> Double? {
        if abs(gLow) < tuning.valueTolerance { return low }
        if abs(gHigh) < tuning.valueTolerance { return high }
        guard (gLow < 0) != (gHigh < 0) else { return nil }
        if let guardDegrees = tuning.wrapGuardDegrees, abs(gHigh - gLow) >= guardDegrees { return nil }
        return refineRoot(
            low: low, high: high, gLow: gLow, gHigh: gHigh,
            tuning: tuning, value: value, slope: slope
        )
    }

    /// Safeguarded Newton-bisection on a sign-changing bracket (rtsafe): Newton when it stays in
    /// range and converges fast enough, bisection otherwise.
    private static func refineRoot(
        low: Double, high: Double, gLow: Double, gHigh: Double, tuning: Tuning,
        value: (Double) -> Double, slope: (Double) -> Double
    ) -> Double {
        var xLow = gLow < 0 ? low : high
        var xHigh = gLow < 0 ? high : low
        var root = 0.5 * (low + high)
        var stepOld = abs(high - low)
        var stepCurrent = stepOld
        var g = value(root)
        var derivative = slope(root)

        for _ in 0..<60 {
            let newtonOutOfRange =
                ((root - xHigh) * derivative - g) * ((root - xLow) * derivative - g) > 0
            let slowConvergence = abs(2.0 * g) > abs(stepOld * derivative)
            if newtonOutOfRange || slowConvergence {
                stepOld = stepCurrent
                stepCurrent = 0.5 * (xHigh - xLow)
                root = xLow + stepCurrent
                if xLow == root { return root }
            } else {
                stepOld = stepCurrent
                stepCurrent = g / derivative
                let previous = root
                root -= stepCurrent
                if previous == root { return root }
            }
            if abs(stepCurrent) < tuning.stepTolerance { return root }
            g = value(root)
            derivative = slope(root)
            if g < 0 { xLow = root } else { xHigh = root }
        }
        return root
    }
}
