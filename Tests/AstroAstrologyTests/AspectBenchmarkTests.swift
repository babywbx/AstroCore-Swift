@testable import AstroAstrology
import AstroCore
import Dispatch
import Foundation
import Testing

@Suite("Aspect Performance Benchmarks", .serialized)
struct AspectBenchmarkTests {
    private func formatMicroseconds(_ value: Double) -> String {
        let precision = value < 1.0 ? 3 : 1
        return String(format: "%.\(precision)f", value)
    }

    private func benchmark(
        iterations: Int,
        warmup: Int = 100,
        _ work: () throws -> Void
    ) rethrows -> (perCallMicroseconds: Double, totalSeconds: Double) {
        for _ in 0..<warmup {
            try work()
        }
        let start = DispatchTime.now().uptimeNanoseconds
        for _ in 0..<iterations {
            try work()
        }
        let elapsedNanoseconds = DispatchTime.now().uptimeNanoseconds - start
        let totalSeconds = Double(elapsedNanoseconds) / 1000000000.0
        let perCallMicroseconds = Double(elapsedNanoseconds) / Double(iterations) / 1000.0
        return (perCallMicroseconds, totalSeconds)
    }

    private static func momentJ2000() throws -> CivilMoment {
        try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
    }

    @Test func benchmarkSeparationPrimitive() {
        let iterations = 2000000
        let result = benchmark(iterations: iterations, warmup: 10000) {
            _ = AstroCalculator.aspectSeparation(longitudeA: 12.3, longitudeB: 211.7, aspectAngleDegrees: 120)
        }
        print("aspectSeparation: \(formatMicroseconds(result.perCallMicroseconds)) µs/call (\(iterations) iterations)")
    }

    @Test func benchmarkSinglePairAspect() throws {
        let moment = try Self.momentJ2000()
        let iterations = 5000
        let result = try benchmark(iterations: iterations, warmup: 100) {
            _ = try AstrologyCalculator.aspect(between: .sun, and: .moon, for: moment)
        }
        print("single-pair aspect: \(formatMicroseconds(result.perCallMicroseconds)) µs/call (\(iterations) iterations)")
    }

    @Test func benchmarkGridAmongStatesByBodyCount() throws {
        let moment = try Self.momentJ2000()
        let groups: [(label: String, bodies: Set<CelestialBody>)] = [
            ("7", [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn]),
            ("10", [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto]),
            ("12", [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto, .meanNode, .lilith])
        ]
        let iterations = 20000
        for group in groups {
            let states = AstroCalculator.states(of: group.bodies, at: moment)
            let pairs = group.bodies.count * (group.bodies.count - 1) / 2
            let result = benchmark(iterations: iterations, warmup: 500) {
                _ = AstrologyCalculator.aspects(among: states, aspectKinds: Set(AspectKind.allCases))
            }
            print("grid[\(group.label) bodies, \(pairs) pairs]: \(formatMicroseconds(result.perCallMicroseconds)) µs/call")
        }
    }

    @Test func benchmarkGridFromMomentChartLevel() throws {
        let moment = try Self.momentJ2000()
        let bodies: Set<CelestialBody> = [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto]
        let iterations = 500
        let result = try benchmark(iterations: iterations, warmup: 20) {
            _ = try AstrologyCalculator.aspects(for: moment, bodies: bodies)
        }
        print("grid from moment (10 bodies incl ephemeris): \(formatMicroseconds(result.perCallMicroseconds)) µs/call")
        print("throughput: \(String(format: "%.0f", 1000000.0 / result.perCallMicroseconds)) charts/sec")
    }

    @Test func benchmarkExactMomentSolve() {
        let seed = 2451545.0
        let moonResult = benchmark(iterations: 50, warmup: 5) {
            _ = AstroCalculator.exactAspectJulianDayTT(of: .sun, and: .moon, aspectAngleDegrees: 0, nearJulianDayTT: seed)
        }
        print("exact moment [Sun-Moon conjunction]: \(formatMicroseconds(moonResult.perCallMicroseconds)) µs/call")
        let slowResult = benchmark(iterations: 50, warmup: 5) {
            _ = AstroCalculator.exactAspectJulianDayTT(of: .saturn, and: .pluto, aspectAngleDegrees: 60, nearJulianDayTT: seed)
        }
        print("exact moment [Saturn-Pluto sextile]: \(formatMicroseconds(slowResult.perCallMicroseconds)) µs/call")
    }

    @Test func benchmarkCrossChartAspects() throws {
        let natalMoment = try Self.momentJ2000()
        let transitMoment = try CivilMoment(year: 2024, month: 6, day: 15, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let bodies: Set<CelestialBody> = [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn]
        let natal = AstroCalculator.states(of: bodies, at: natalMoment)
        let transit = AstroCalculator.states(of: bodies, at: transitMoment)
        let iterations = 10000
        let result = benchmark(iterations: iterations, warmup: 200) {
            _ = AstrologyCalculator.crossAspects(natal: natal, transit: transit)
        }
        print("cross-chart aspects (7x7 = 49 pairs): \(formatMicroseconds(result.perCallMicroseconds)) µs/call")
    }
}
