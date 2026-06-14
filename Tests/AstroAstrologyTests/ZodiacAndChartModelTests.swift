@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

@Suite("Zodiac and Chart Models")
struct ZodiacAndChartModelTests {
    @Test func zodiacSignMetadataAndContainmentStayStable() {
        #expect(ZodiacSign.allCases.count == 12)
        for sign in ZodiacSign.allCases {
            #expect(!sign.name.isEmpty)
            #expect(!sign.emoji.isEmpty)
            #expect(sign.startLongitude == Double(sign.rawValue) * 30.0)
            #expect(sign.contains(longitude: sign.startLongitude))
            #expect(!sign.contains(longitude: sign.startLongitude + 30.0))
        }
        #expect(ZodiacSign.capricorn.startLongitude == 270.0)
        #expect(ZodiacSign.pisces.contains(longitude: 359.9))
        #expect(ZodiacSign.aries.contains(longitude: 360.0))
        #expect(!ZodiacSign.taurus.contains(longitude: 29.999))
    }

    @Test func zodiacMapperDerivesSignDegreeAndBoundaryFlags() {
        #expect(ZodiacMapper.sign(forLongitude: -0.1) == .pisces)
        #expect(ZodiacMapper.sign(forLongitude: 0.0) == .aries)
        #expect(ZodiacMapper.sign(forLongitude: 30.0) == .taurus)
        #expect(abs(ZodiacMapper.degreeInSign(longitude: 389.75) - 29.75) < 1e-12)
        #expect(ZodiacMapper.isBoundaryCase(longitude: 29.5))
        #expect(ZodiacMapper.isBoundaryCase(longitude: 30.0))
        #expect(!ZodiacMapper.isBoundaryCase(longitude: 15.0))
        #expect(!ZodiacMapper.isBoundaryCase(longitude: .nan))
    }

    @Test func houseSystemsExposeStableOrderingAndMetadata() {
        #expect(HouseSystem.allCases == [
            .equalASC, .equalMC, .wholeSign, .vehlow,
            .porphyry, .sripati,
            .placidus, .koch, .alcabitius,
            .campanus, .regiomontanus, .morinus, .topocentric,
            .horizontal, .meridian, .carter
        ])
        #expect(HouseSystem.placidus.hasPolarLimit)
        #expect(HouseSystem.koch.hasPolarLimit)
        #expect(HouseSystem.alcabitius.hasPolarLimit)
        #expect(!HouseSystem.topocentric.hasPolarLimit)
        #expect(HouseSystem.equalASC.displayName == "Equal (ASC)")
        #expect(HouseSystem.horizontal.displayName == "Horizontal / Azimuthal")
        #expect(HouseSystem.meridian.displayName == "Meridian / Axial Rotation")
        #expect(HouseSystem.carter.displayName == "Carter Poli-Equatorial")
    }

    @Test func anglesAndAstrologyErrorStayEquatableAndDerivedCorrectly() {
        #expect(
            AstrologyError.houseSystemUndefinedAtLatitude(system: .placidus, latitude: 75.0)
                == .houseSystemUndefinedAtLatitude(system: .placidus, latitude: 75.0)
        )
        let angles = Angles(ascendant: 42.0, midheaven: 330.0, vertex: 120.0)
        #expect(angles.descendant == 222.0)
        #expect(angles.imumCoeli == 150.0)
        #expect(angles.vertex == 120.0)
    }

    @Test func houseResultTracksRequestedAndResolvedSystems() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21, hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coordinate = try GeoCoordinate(latitude: 80.0, longitude: 0.0)
        let result = try AstrologyCalculator.houses(
            for: moment,
            coordinate: coordinate,
            system: .placidus,
            polarFallback: .wholeSign
        )
        #expect(result.requestedSystem == .placidus)
        #expect(result.resolvedSystem == .wholeSign)
        #expect(!result.usedRequestedSystem)
        AstrologyTestSupport.expectValidCusps(result.cusps)
    }

    @Test func chartAndGauquelinRoundTripThroughJSON() throws {
        let fixture = try AstrologyTestSupport.newYork1990()
        let chart = try AstrologyCalculator.natalChart(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            bodies: [.sun, .moon, .mercury],
            system: .porphyry
        )
        let chartPayload = try JSONEncoder().encode(chart)
        let roundTripped = try JSONDecoder().decode(NatalChart.self, from: chartPayload)
        let gauquelin = try AstrologyCalculator.gauquelinSectors(
            for: fixture.moment, coordinate: fixture.coordinate
        )
        let gauquelinPayload = try JSONEncoder().encode(gauquelin)
        let gauquelinRoundTrip = try JSONDecoder().decode(
            GauquelinResult.self, from: gauquelinPayload
        )
        #expect(chart.moment == roundTripped.moment)
        #expect(chart.coordinate == roundTripped.coordinate)
        #expect(chart.positions == roundTripped.positions)
        #expect(chart.houses == roundTripped.houses)
        #expect(gauquelin == gauquelinRoundTrip)
    }
}
