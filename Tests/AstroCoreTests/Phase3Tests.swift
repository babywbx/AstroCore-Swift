import Testing

@testable import AstroCore

// Phase 3: Planetary Ephemeris Tests

@Suite("Solar Position Tests")
struct SolarPositionTests {
    // Sun position at J2000.0 (2000-01-01 12:00 TT)
    // Expected: ~280.5° ecliptic longitude (Capricorn)
    @Test func sunAtJ2000() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.sunPosition(for: moment)
        // Sun around Jan 1 should be ~280° (Capricorn)
        #expect(pos.sign == .capricorn)
        #expect(abs(pos.longitude - 280.5) < 1.0)
    }

    // Summer solstice 2000: Sun at ~90° (Cancer)
    @Test func summerSolstice2000() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0, second: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.sunPosition(for: moment)
        #expect(abs(pos.longitude - 90.0) < 1.0)
        #expect(pos.sign == .gemini || pos.sign == .cancer)
    }

    // Vernal equinox: Sun at ~0° (Aries)
    @Test func vernalEquinox2000() throws {
        let moment = try CivilMoment(
            year: 2000, month: 3, day: 20,
            hour: 12, minute: 0, second: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.sunPosition(for: moment)
        // Sun near 0° at vernal equinox
        #expect(pos.longitude < 2.0 || pos.longitude > 358.0)
    }
}

@Suite("Moon Position Tests")
struct MoonPositionTests {
    @Test func moonAtJ2000() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.moonPosition(for: moment)
        // Moon moves ~13°/day, exact position at J2000.0 depends on ephemeris
        #expect(pos.longitude >= 0 && pos.longitude < 360)
        #expect(abs(pos.latitude) < 6.0) // Moon latitude within ±5.3°
    }

    @Test func moonSignChanges() throws {
        // Moon changes sign roughly every 2.5 days
        let moment1 = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 0, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let moment2 = try CivilMoment(
            year: 2000, month: 1, day: 5, hour: 0, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos1 = try AstroCalculator.moonPosition(for: moment1)
        let pos2 = try AstroCalculator.moonPosition(for: moment2)
        // After 4 days, Moon should have moved ~52°
        let diff = (pos2.longitude - pos1.longitude + 360.0)
            .truncatingRemainder(dividingBy: 360.0)
        #expect(diff > 40 && diff < 70)
    }
}

@Suite("Planetary Position Tests")
struct PlanetaryPositionTests {
    // Mercury at J2000.0
    @Test func mercuryAtJ2000() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.planetPosition(.mercury, for: moment)
        #expect(pos.longitude >= 0 && pos.longitude < 360)
        // Mercury latitude should be within ±7°
        #expect(abs(pos.latitude) < 8.0)
    }

    // Venus at J2000.0
    @Test func venusAtJ2000() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.planetPosition(.venus, for: moment)
        #expect(pos.longitude >= 0 && pos.longitude < 360)
    }

    // Mars at J2000.0
    @Test func marsAtJ2000() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.planetPosition(.mars, for: moment)
        #expect(pos.longitude >= 0 && pos.longitude < 360)
    }

    // Jupiter at J2000.0
    @Test func jupiterAtJ2000() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.planetPosition(.jupiter, for: moment)
        #expect(pos.longitude >= 0 && pos.longitude < 360)
    }

    // Saturn at J2000.0
    @Test func saturnAtJ2000() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let pos = try AstroCalculator.planetPosition(.saturn, for: moment)
        #expect(pos.longitude >= 0 && pos.longitude < 360)
    }

    // Sun via planetPosition should match sunPosition
    @Test func sunViaPlanetPosition() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 15, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let direct = try AstroCalculator.sunPosition(for: moment)
        let via = try AstroCalculator.planetPosition(.sun, for: moment)
        #expect(abs(direct.longitude - via.longitude) < 0.0001)
    }
}

@Suite("Natal Positions Tests")
struct NatalPositionsTests {
    @Test func fullNatalChart() throws {
        let moment = try CivilMoment(
            year: 1990, month: 8, day: 15,
            hour: 14, minute: 30, second: 0,
            timeZoneIdentifier: "America/New_York"
        )
        let coord = try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)

        let natal = try AstroCalculator.natalPositions(
            for: moment,
            coordinate: coord,
            bodies: [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn],
            includeAscendant: true
        )

        // All 7 bodies should be present
        #expect(natal.bodies.count == 7)
        #expect(natal.ascendant != nil)

        // Sun in Leo around Aug 15
        #expect(natal.bodies[.sun]?.sign == .leo)

        // Verify all longitudes are valid
        for (_, pos) in natal.bodies {
            #expect(pos.longitude >= 0 && pos.longitude < 360)
        }
    }

    @Test func bodiesOnlyNoAscendant() throws {
        let moment = try CivilMoment(
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneIdentifier: "UTC"
        )
        let natal = try AstroCalculator.natalPositions(
            for: moment,
            bodies: [.sun, .moon],
            includeAscendant: false
        )
        #expect(natal.ascendant == nil)
        #expect(natal.bodies.count == 2)
    }
}

