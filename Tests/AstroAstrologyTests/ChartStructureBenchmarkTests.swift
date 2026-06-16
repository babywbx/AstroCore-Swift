@testable import AstroAstrology
import AstroCore
import Dispatch
import Foundation
import Testing

@Suite("Chart Structure Benchmarks", .serialized)
struct ChartStructureBenchmarkTests {
    private func formatMicroseconds(_ value: Double) -> String {
        let precision = value < 1.0 ? 3 : 1
        return String(format: "%.\(precision)f", value)
    }

    private func benchmark(
        iterations: Int,
        warmup: Int = 100,
        _ work: () -> Void
    ) -> (perCallMicroseconds: Double, totalSeconds: Double) {
        for _ in 0..<warmup {
            work()
        }
        let start = DispatchTime.now().uptimeNanoseconds
        for _ in 0..<iterations {
            work()
        }
        let elapsedNanoseconds = DispatchTime.now().uptimeNanoseconds - start
        let totalSeconds = Double(elapsedNanoseconds) / 1000000000.0
        let perCallMicroseconds = Double(elapsedNanoseconds) / Double(iterations) / 1000.0
        return (perCallMicroseconds, totalSeconds)
    }

    @Test func benchmarkPatternDetection() throws {
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30,
            timeZoneIdentifier: "America/New_York"
        )
        let bodies: Set<CelestialBody> = [
            .sun, .moon, .mercury, .venus, .mars, .jupiter,
            .saturn, .uranus, .neptune, .pluto, .meanNode, .lilith
        ]
        let grid = try AstrologyCalculator.aspects(for: moment, bodies: bodies)
        let iterations = 5000
        let result = benchmark(iterations: iterations) {
            _ = AstrologyCalculator.patterns(in: grid)
        }
        print("pattern detection [12 bodies, \(grid.aspects.count) edges]: \(formatMicroseconds(result.perCallMicroseconds)) µs/call")
    }
}
