import Testing
import Foundation

@testable import AstroCore

// Verify exact computed values haven't drifted after optimization
@Suite("Precision Drift Check")
struct PrecisionDriftCheck {
    // Known-good values from JPL Horizons validation session
    // Any drift here means the optimization changed computation results

    @Test func sunPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = try AstroCalculator.sunPosition(for: m)
        // Previously verified: 280.3689153545049
        let diff = abs(pos.longitude - 280.3689153545049)
        print("Sun drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Sun longitude drifted!")
    }

    @Test func moonPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = try AstroCalculator.moonPosition(for: m)
        // Previously verified: 223.32372926144598
        let diff = abs(pos.longitude - 223.32372926144598)
        print("Moon drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Moon longitude drifted!")
    }

    @Test func mercuryPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = try AstroCalculator.planetPosition(.mercury, for: m)
        let diff = abs(pos.longitude - 271.8950304408318)
        print("Mercury drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Mercury longitude drifted!")
    }

    @Test func venusPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = try AstroCalculator.planetPosition(.venus, for: m)
        let diff = abs(pos.longitude - 241.57032362068446)
        print("Venus drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Venus longitude drifted!")
    }

    @Test func marsPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = try AstroCalculator.planetPosition(.mars, for: m)
        let diff = abs(pos.longitude - 327.96723158721085)
        print("Mars drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Mars longitude drifted!")
    }

    @Test func jupiterPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = try AstroCalculator.planetPosition(.jupiter, for: m)
        let diff = abs(pos.longitude - 25.25167060125795)
        print("Jupiter drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Jupiter longitude drifted!")
    }

    @Test func saturnPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = try AstroCalculator.planetPosition(.saturn, for: m)
        let diff = abs(pos.longitude - 40.392783528176174)
        print("Saturn drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Saturn longitude drifted!")
    }

    @Test func ascendantPrecision() throws {
        let m = try CivilMoment(year: 1990, month: 8, day: 15, hour: 14, minute: 30, timeZoneIdentifier: "America/New_York")
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let asc = try AstroCalculator.ascendant(for: m, coordinate: coord)
        let diff = abs(asc.eclipticLongitude - 240.93003034224864)
        print("ASC drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Ascendant longitude drifted!")
    }

    @Test func natalBatchVsSingle() throws {
        let m = try CivilMoment(year: 1990, month: 8, day: 15, hour: 14, minute: 30, timeZoneIdentifier: "America/New_York")
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)

        // Compute individually
        let sunSingle = try AstroCalculator.sunPosition(for: m)
        let moonSingle = try AstroCalculator.moonPosition(for: m)
        let mercSingle = try AstroCalculator.planetPosition(.mercury, for: m)
        let ascSingle = try AstroCalculator.ascendant(for: m, coordinate: coord)

        // Compute via batch
        let natal = try AstroCalculator.natalPositions(
            for: m, coordinate: coord,
            bodies: [.sun, .moon, .mercury],
            includeAscendant: true
        )

        // Batch and single must produce identical results
        #expect(natal.bodies[.sun]!.longitude == sunSingle.longitude, "Sun batch != single")
        #expect(natal.bodies[.moon]!.longitude == moonSingle.longitude, "Moon batch != single")
        #expect(natal.bodies[.mercury]!.longitude == mercSingle.longitude, "Mercury batch != single")
        #expect(natal.ascendant!.eclipticLongitude == ascSingle.eclipticLongitude, "ASC batch != single")
        print("Batch vs single: identical ✓")
    }
}
