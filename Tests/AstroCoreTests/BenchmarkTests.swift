@testable import AstroCore
import Dispatch
import Foundation
import Testing

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
        let totalSeconds = Double(elapsedNanoseconds) / 1000000000.0
        let perCallMicroseconds = Double(elapsedNanoseconds) / Double(iterations) / 1000.0
        return (perCallMicroseconds, totalSeconds)
    }

    @Test func benchmarkCivilMomentConstruction() throws {
        let iterations = 5000
        let forward = try benchmark(iterations: iterations) {
            _ = try CivilMoment(
                year: 2000, month: 6, day: 21, hour: 12, minute: 0,
                timeZoneIdentifier: "America/New_York"
            )
        }
        print("🏙️  CivilMoment forward: \(formatMicroseconds(forward.perCallMicroseconds)) µs/call")
        let jd = try CivilMoment(
            year: 2000, month: 6, day: 21, hour: 12, minute: 0,
            timeZoneIdentifier: "America/New_York"
        ).julianDayUT
        let bridge = try benchmark(iterations: iterations) {
            _ = try CivilMoment(julianDayUT: jd, timeZoneIdentifier: "America/New_York")
        }
        print("🌉  CivilMoment JD bridge: \(formatMicroseconds(bridge.perCallMicroseconds)) µs/call")
    }

    @Test func benchmarkSunPosition() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let iterations = 5000
        let result = benchmark(iterations: iterations) {
            _ = AstroCalculator.sunPosition(for: moment)
        }
        print("☀️  Sun position: \(formatMicroseconds(result.perCallMicroseconds)) µs/call (\(iterations) iterations, \(String(format: "%.3f", result.totalSeconds))s total)")
    }

    @Test func benchmarkMoonPosition() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let iterations = 20000
        let result = benchmark(iterations: iterations, warmup: 500) {
            _ = AstroCalculator.moonPosition(for: moment)
        }
        print("🌙  Moon position: \(formatMicroseconds(result.perCallMicroseconds)) µs/call (\(iterations) iterations, \(String(format: "%.3f", result.totalSeconds))s total)")
    }

    @Test func benchmarkPlanetPosition() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let bodies: [CelestialBody] = [.mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto]
        let iterations = 500
        for body in bodies {
            let result = benchmark(iterations: iterations) {
                _ = AstroCalculator.planetPosition(body, for: moment)
            }
            print("🪐  \(body) position: \(formatMicroseconds(result.perCallMicroseconds)) µs/call")
        }
    }

    @Test func benchmarkDerivedCoordinates() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        let iterations = 2000
        let eq = benchmark(iterations: iterations) {
            _ = AstroCalculator.equatorial(of: .mars, at: moment)
        }
        print("📐  Mars equatorial: \(formatMicroseconds(eq.perCallMicroseconds)) µs/call")
        let helio = benchmark(iterations: iterations) {
            _ = AstroCalculator.heliocentric(of: .mars, at: moment)
        }
        print("☉  Mars heliocentric: \(formatMicroseconds(helio.perCallMicroseconds)) µs/call")
    }

    @Test func benchmarkHorizontal() throws {
        let moment = try CivilMoment(
            year: 2024, month: 6, day: 21, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        let observer = try GeoCoordinate(latitude: 51.4779, longitude: -0.0015, elevation: 45.0)
        let iterations = 2000
        let result = benchmark(iterations: iterations) {
            _ = AstroCalculator.horizontal(of: .moon, at: moment, observer: observer)
        }
        print("🧭  Moon horizontal: \(formatMicroseconds(result.perCallMicroseconds)) µs/call")
    }

    @Test func benchmarkIllumination() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 13, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        let iterations = 2000
        let result = benchmark(iterations: iterations) {
            _ = AstroCalculator.illumination(of: .moon, at: moment)
        }
        print("🌗  Moon illumination: \(formatMicroseconds(result.perCallMicroseconds)) µs/call")
    }

    @Test func benchmarkEquationOfTime() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 13, hour: 12, minute: 0, timeZoneIdentifier: "UTC"
        )
        let jd = AstroCalculator.julianDayUT(for: moment)
        let iterations = 2000
        let result = benchmark(iterations: iterations) {
            _ = AstroCalculator.equationOfTime(julianDayUT: jd)
        }
        print("⏱️  Equation of time: \(formatMicroseconds(result.perCallMicroseconds)) µs/call")
    }
}
