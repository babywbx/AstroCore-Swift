@testable import AstroCore
import Dispatch
import Foundation
import Testing

@Suite("Event Benchmarks", .serialized)
struct EventBenchmarkTests {
    private func formatMicroseconds(_ value: Double) -> String {
        let precision = value < 1.0 ? 3 : 1
        return String(format: "%.\(precision)f", value)
    }

    private func benchmark(
        iterations: Int,
        warmup: Int = 50,
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

    @Test func benchmarkStationSolve() throws {
        let seed = try CivilMoment(
            year: 2020, month: 2, day: 17, hour: 0, minute: 0, timeZoneIdentifier: "UTC"
        ).julianDayTT
        let iterations = 200
        let result = benchmark(iterations: iterations, warmup: 20) {
            _ = AstroCalculator.stationJulianDayTT(
                of: .mercury, nearJulianDayTT: seed, searchWindowDays: 30.0
            )
        }
        print("station solve [Mercury, root nearby]: \(formatMicroseconds(result.perCallMicroseconds)) µs/call")
    }

    @Test func benchmarkStationEnumerationYear() throws {
        let start = try CivilMoment(
            year: 2020, month: 1, day: 1, hour: 0, minute: 0, timeZoneIdentifier: "UTC"
        ).julianDayTT
        let end = start + 366.0
        let iterations = 20
        let result = benchmark(iterations: iterations, warmup: 3) {
            _ = AstroCalculator.stationJulianDaysTT(
                of: .mercury, fromJulianDayTT: start, throughJulianDayTT: end
            )
        }
        print("station enumeration [Mercury, 1 year]: \(formatMicroseconds(result.perCallMicroseconds)) µs/call")
    }
}
