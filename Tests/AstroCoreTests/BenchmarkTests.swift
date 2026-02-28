import Testing
import Foundation
import Dispatch

@testable import AstroCore

@Suite("Performance Benchmarks", .serialized)
struct BenchmarkTests {
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
        let totalSeconds = Double(elapsedNanoseconds) / 1_000_000_000.0
        let perCallMicroseconds = Double(elapsedNanoseconds) / Double(iterations) / 1_000.0
        return (perCallMicroseconds, totalSeconds)
    }

    @Test func benchmarkSunPosition() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let iterations = 10000
        let result = try benchmark(iterations: iterations) {
            _ = try AstroCalculator.sunPosition(for: moment)
        }
        print("☀️  Sun position: \(formatMicroseconds(result.perCallMicroseconds)) µs/call (\(iterations) iterations, \(String(format: "%.3f", result.totalSeconds))s total)")
    }

    @Test func benchmarkMoonPosition() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let iterations = 100000
        let result = try benchmark(iterations: iterations, warmup: 1000) {
            _ = try AstroCalculator.moonPosition(for: moment)
        }
        print("🌙  Moon position: \(formatMicroseconds(result.perCallMicroseconds)) µs/call (\(iterations) iterations, \(String(format: "%.3f", result.totalSeconds))s total)")
    }

    @Test func benchmarkPlanetPosition() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let bodies: [CelestialBody] = [.mercury, .venus, .mars, .jupiter, .saturn]
        let iterations = 5000
        for body in bodies {
            let result = try benchmark(iterations: iterations) {
                _ = try AstroCalculator.planetPosition(body, for: moment)
            }
            print("🪐  \(body) position: \(formatMicroseconds(result.perCallMicroseconds)) µs/call")
        }
    }

    @Test func benchmarkAscendant() throws {
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30,
            timeZoneIdentifier: "America/New_York"
        )
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let iterations = 1_000_000
        let result = try benchmark(iterations: iterations, warmup: 1000) {
            _ = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        }
        print("♈  Ascendant: \(formatMicroseconds(result.perCallMicroseconds)) µs/call (\(iterations) iterations, \(String(format: "%.3f", result.totalSeconds))s total)")
    }

    @Test func benchmarkFullNatalChart() throws {
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30,
            timeZoneIdentifier: "America/New_York"
        )
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let iterations = 2000
        let result = try benchmark(iterations: iterations, warmup: 20) {
            _ = try AstroCalculator.natalPositions(
                for: moment,
                coordinate: coord,
                bodies: [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn],
                includeAscendant: true
            )
        }
        let perCallMs = result.perCallMicroseconds / 1000.0
        print("📊  Full natal chart (7 bodies + ASC): \(formatMicroseconds(result.perCallMicroseconds)) µs/call (\(String(format: "%.2f", perCallMs)) ms)")
        print("    Throughput: \(String(format: "%.0f", 1_000_000.0 / result.perCallMicroseconds)) charts/sec")
    }
}
