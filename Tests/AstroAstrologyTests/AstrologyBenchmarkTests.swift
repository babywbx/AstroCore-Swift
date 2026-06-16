@testable import AstroAstrology
import AstroCore
import Dispatch
import Foundation
import Testing

@Suite("Astrology Performance Benchmarks", .serialized)
struct AstrologyBenchmarkTests {
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

    @Test func benchmarkAscendant() throws {
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30,
            timeZoneIdentifier: "America/New_York"
        )
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let iterations = 200000
        let result = try benchmark(iterations: iterations, warmup: 1000) {
            _ = try AstrologyCalculator.ascendant(for: moment, coordinate: coord)
        }
        print("ascendant: \(formatMicroseconds(result.perCallMicroseconds)) µs/call (\(iterations) iterations, \(String(format: "%.3f", result.totalSeconds))s total)")
    }

    @Test func benchmarkRiseSetEvents() throws {
        let date = try CivilMoment(
            year: 2020, month: 3, day: 20, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        let coordinate = try GeoCoordinate(latitude: 51.5, longitude: 0.0)
        let iterations = 200
        let result = try benchmark(iterations: iterations, warmup: 20) {
            _ = try AstrologyCalculator.riseSetEvents(of: .sun, on: date, coordinate: coordinate)
        }
        print("riseSetEvents [Sun, single day]: \(formatMicroseconds(result.perCallMicroseconds)) µs/call")
    }

    @Test func benchmarkHouseSystems() throws {
        let fixture = try AstrologyTestSupport.newYork1990()
        let iterations = 5000

        for system in HouseSystem.allCases {
            let result = try benchmark(iterations: iterations, warmup: 100) {
                _ = try AstrologyCalculator.houses(
                    for: fixture.moment,
                    coordinate: fixture.coordinate,
                    system: system
                )
            }
            print(
                "houses[\(system.displayName)]: \(formatMicroseconds(result.perCallMicroseconds)) µs/call (\(iterations) iterations)"
            )
        }
    }

    @Test func benchmarkFullNatalPositions() throws {
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30,
            timeZoneIdentifier: "America/New_York"
        )
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let iterations = 200
        let result = try benchmark(iterations: iterations, warmup: 20) {
            _ = try AstrologyCalculator.natalPositions(
                for: moment,
                coordinate: coord,
                bodies: [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn],
                includeAscendant: true
            )
        }
        let perCallMs = result.perCallMicroseconds / 1000.0
        print("full natal positions (7 bodies + asc): \(formatMicroseconds(result.perCallMicroseconds)) µs/call (\(String(format: "%.2f", perCallMs)) ms)")
        print("throughput: \(String(format: "%.0f", 1000000.0 / result.perCallMicroseconds)) charts/sec")
    }

    @Test func benchmarkMotionRichNatalStates() throws {
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30,
            timeZoneIdentifier: "America/New_York"
        )
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let iterations = 200
        let result = try benchmark(iterations: iterations, warmup: 20) {
            _ = try AstrologyCalculator.natalStates(
                for: moment,
                coordinate: coord,
                bodies: [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn],
                includeAscendant: true
            )
        }
        let perCallMs = result.perCallMicroseconds / 1000.0
        print("motion-rich natal states (7 bodies + asc): \(formatMicroseconds(result.perCallMicroseconds)) µs/call (\(String(format: "%.2f", perCallMs)) ms)")
        print("throughput: \(String(format: "%.0f", 1000000.0 / result.perCallMicroseconds)) charts/sec")
    }
}
