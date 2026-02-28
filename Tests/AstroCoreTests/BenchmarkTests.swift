import Testing
import Foundation

@testable import AstroCore

@Suite("Performance Benchmarks")
struct BenchmarkTests {
    @Test func benchmarkSunPosition() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let iterations = 10000
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = try AstroCalculator.sunPosition(for: moment)
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let perCall = elapsed / Double(iterations) * 1_000_000 // µs
        print("☀️  Sun position: \(String(format: "%.1f", perCall)) µs/call (\(iterations) iterations, \(String(format: "%.3f", elapsed))s total)")
    }

    @Test func benchmarkMoonPosition() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let iterations = 10000
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = try AstroCalculator.moonPosition(for: moment)
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let perCall = elapsed / Double(iterations) * 1_000_000
        print("🌙  Moon position: \(String(format: "%.1f", perCall)) µs/call (\(iterations) iterations, \(String(format: "%.3f", elapsed))s total)")
    }

    @Test func benchmarkPlanetPosition() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let bodies: [CelestialBody] = [.mercury, .venus, .mars, .jupiter, .saturn]
        let iterations = 5000
        for body in bodies {
            let start = CFAbsoluteTimeGetCurrent()
            for _ in 0..<iterations {
                _ = try AstroCalculator.planetPosition(body, for: moment)
            }
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            let perCall = elapsed / Double(iterations) * 1_000_000
            print("🪐  \(body) position: \(String(format: "%.1f", perCall)) µs/call")
        }
    }

    @Test func benchmarkAscendant() throws {
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30,
            timeZoneIdentifier: "America/New_York"
        )
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let iterations = 10000
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = try AstroCalculator.ascendant(for: moment, coordinate: coord)
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let perCall = elapsed / Double(iterations) * 1_000_000
        print("♈  Ascendant: \(String(format: "%.1f", perCall)) µs/call (\(iterations) iterations, \(String(format: "%.3f", elapsed))s total)")
    }

    @Test func benchmarkFullNatalChart() throws {
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15, hour: 14, minute: 30,
            timeZoneIdentifier: "America/New_York"
        )
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let iterations = 2000
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = try AstroCalculator.natalPositions(
                for: moment,
                coordinate: coord,
                bodies: [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn],
                includeAscendant: true
            )
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let perCall = elapsed / Double(iterations) * 1_000_000
        let perCallMs = perCall / 1000.0
        print("📊  Full natal chart (7 bodies + ASC): \(String(format: "%.1f", perCall)) µs/call (\(String(format: "%.2f", perCallMs)) ms)")
        print("    Throughput: \(String(format: "%.0f", 1_000_000.0 / perCall)) charts/sec")
    }
}
