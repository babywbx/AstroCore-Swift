import Testing
import Foundation

@testable import AstroCore

// Verify exact computed values haven't drifted after implementation changes
@Suite("Precision Drift Check")
struct PrecisionDriftCheck {
    // Known-good regression values.
    // Any drift here means the implementation changed numerical output.

    @Test func sunPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = AstroCalculator.sunPosition(for: m)
        let diff = abs(pos.longitude - 280.3689148247274)
        print("Sun drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Sun longitude drifted!")
    }

    @Test func moonPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = AstroCalculator.moonPosition(for: m)
        let diff = abs(pos.longitude - 223.32392850044735)
        print("Moon drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Moon longitude drifted!")
    }

    @Test func mercuryPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = AstroCalculator.planetPosition(.mercury, for: m)
        let diff = abs(pos.longitude - 271.88929113413883)
        print("Mercury drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Mercury longitude drifted!")
    }

    @Test func venusPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = AstroCalculator.planetPosition(.venus, for: m)
        let diff = abs(pos.longitude - 241.56582103209644)
        print("Venus drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Venus longitude drifted!")
    }

    @Test func marsPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = AstroCalculator.planetPosition(.mars, for: m)
        let diff = abs(pos.longitude - 327.9633099594107)
        print("Mars drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Mars longitude drifted!")
    }

    @Test func jupiterPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = AstroCalculator.planetPosition(.jupiter, for: m)
        let diff = abs(pos.longitude - 25.25310623703263)
        print("Jupiter drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Jupiter longitude drifted!")
    }

    @Test func saturnPrecision() throws {
        let m = try CivilMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        let pos = AstroCalculator.planetPosition(.saturn, for: m)
        let diff = abs(pos.longitude - 40.39564784286394)
        print("Saturn drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Saturn longitude drifted!")
    }

    @Test func ascendantPrecision() throws {
        let m = try CivilMoment(year: 1990, month: 8, day: 15, hour: 14, minute: 30, timeZoneIdentifier: "America/New_York")
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let asc = try AstroCalculator.ascendant(for: m, coordinate: coord)
        let diff = abs(asc.eclipticLongitude - 240.93003034223938)
        print("ASC drift: \(diff)° (\(diff * 3600)″)")
        #expect(diff < 1e-10, "Ascendant longitude drifted!")
    }

    @Test func natalBatchVsSingle() throws {
        let m = try CivilMoment(year: 1990, month: 8, day: 15, hour: 14, minute: 30, timeZoneIdentifier: "America/New_York")
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)

        // Compute individually
        let sunSingle = AstroCalculator.sunPosition(for: m)
        let moonSingle = AstroCalculator.moonPosition(for: m)
        let mercSingle = AstroCalculator.planetPosition(.mercury, for: m)
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
