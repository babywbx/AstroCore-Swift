@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

private let angleAlignedSystems: [HouseSystem] = [
    .porphyry, .placidus, .koch, .alcabitius, .campanus, .regiomontanus, .topocentric
]

private let parisHorizontalCusps: [Double] = [
    95.494990239742, 143.569151565527, 185.931903802532, 210.219647778581,
    227.900895333892, 246.695123421919, 275.494990239742, 323.569151565527,
    5.931903802532, 30.219647778581, 47.900895333892, 66.695123421919
]

private let parisCarterCusps: [Double] = [
    135.182551935024, 166.573370917438, 199.121591708568, 230.089433681251,
    258.637397350727, 286.269954959984, 315.182551935024, 346.573370917438,
    19.121591708568, 50.089433681251, 78.637397350727, 106.269954959984
]

private let parisMeridianCusps: [Double] = [
    116.119644373870, 145.867620674753, 177.951802084253, 210.219647778581,
    240.289669765802, 268.275632927776, 296.119644373870, 325.867620674753,
    357.951802084253, 30.219647778581, 60.289669765802, 88.275632927776
]

private let parisGauquelinSectors: [Double] = [
    135.182551935024, 126.067478434068, 116.262229979312, 105.670118263420,
    94.208527331423, 81.885489972201, 68.901537510294, 55.663065664900,
    42.642400232636, 30.219647778581, 18.626930852629, 7.965617835043,
    358.242379796063, 349.403458567605, 341.362145933543, 334.018259004823,
    327.270217892909, 321.021391487422, 315.182551935024, 306.067478434068,
    296.262229979312, 285.670118263420, 274.208527331423, 261.885489972201,
    248.901537510294, 235.663065664900, 222.642400232636, 210.219647778581,
    198.626930852629, 187.965617835043, 178.242379796063, 169.403458567605,
    161.362145933543, 154.018259004823, 147.270217892909, 141.021391487422
]

@Suite("House Systems")
struct HouseSystemTests {
    @Test func midheavenFormulaAndVertexBehaveAsExpected() {
        let epsilon = 23.4393
        let cardinals = [0.0, 90.0, 180.0, 270.0]
        for armc in cardinals {
            let midheaven = AnglesEngine.midheavenLongitude(
                lastDegrees: armc,
                trueObliquityDegrees: epsilon
            )
            AstrologyTestSupport.expectCircularlyEqual(midheaven, armc, tolerance: 1e-9)
        }

        for armc in stride(from: 5.0, through: 355.0, by: 7.0)
            where abs(armc - 90.0) > 1e-3 && abs(armc - 270.0) > 1e-3
        {
            let midheaven = AnglesEngine.midheavenLongitude(
                lastDegrees: armc,
                trueObliquityDegrees: epsilon
            )
            let lhs = TrigDeg.tan(midheaven) * TrigDeg.cos(epsilon)
            let rhs = TrigDeg.tan(armc)
            #expect(abs(lhs - rhs) < 1e-9)
        }

        #expect(
            AnglesEngine.vertexLongitude(
                lastDegrees: 120.0,
                trueObliquityDegrees: epsilon,
                latitudeDegrees: 0.0
            ) == nil
        )
        #expect(
            AnglesEngine.vertexLongitude(
                lastDegrees: 120.0,
                trueObliquityDegrees: epsilon,
                latitudeDegrees: 51.5
            ) != nil
        )
        #expect(
            AnglesEngine.vertexLongitude(
                lastDegrees: 120.0,
                trueObliquityDegrees: epsilon,
                latitudeDegrees: -33.8
            ) != nil
        )

        let equatorialSemiArc = SemiArc.compute(
            eclipticLongitude: 0.0,
            obliquity: epsilon,
            latitude: 0.0
        )
        #expect(abs(equatorialSemiArc.declinationDegrees) < 1e-12)
        #expect(abs(equatorialSemiArc.rightAscensionDegrees) < 1e-12)
        #expect(abs((equatorialSemiArc.semiDiurnalArc ?? 0.0) - 90.0) < 1e-9)
        #expect(!equatorialSemiArc.isCircumpolar)

        let circumpolarSemiArc = SemiArc.compute(
            eclipticLongitude: 90.0,
            obliquity: epsilon,
            latitude: 80.0
        )
        #expect(abs(circumpolarSemiArc.declinationDegrees - epsilon) < 1e-9)
        #expect(circumpolarSemiArc.semiDiurnalArc == nil)
        #expect(circumpolarSemiArc.isCircumpolar)
    }

    @Test func allSystemsProduceValidCuspsAcrossRepresentativeCities() throws {
        for fixture in try AstrologyTestSupport.coreHouseFixtures() {
            for system in HouseSystem.allCases {
                let result = try AstrologyCalculator.houses(
                    for: fixture.moment,
                    coordinate: fixture.coordinate,
                    system: system
                )
                #expect(result.requestedSystem == system)
                #expect(result.resolvedSystem == system)
                #expect(result.usedRequestedSystem)
                AstrologyTestSupport.expectValidCusps(result.cusps)
                AstrologyTestSupport.expectCuspPartition(result.cusps)
            }
        }
    }

    @Test func equalDivisionSystemsFollowTheirDefinitions() throws {
        let fixture = try AstrologyTestSupport.newYork1990()

        let equalAsc = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .equalASC
        )
        AstrologyTestSupport.expectCircularlyEqual(
            equalAsc.cusps[0].eclipticLongitude,
            equalAsc.angles.ascendant,
            tolerance: 1e-9
        )
        for index in 0..<11 {
            let arc = AstrologyTestSupport.forwardArc(
                equalAsc.cusps[index].eclipticLongitude,
                equalAsc.cusps[index + 1].eclipticLongitude
            )
            #expect(abs(arc - 30.0) < 1e-9)
        }

        let equalMC = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .equalMC
        )
        AstrologyTestSupport.expectCircularlyEqual(
            equalMC.cusps[9].eclipticLongitude,
            equalMC.angles.midheaven,
            tolerance: 1e-9
        )

        let vehlow = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .vehlow
        )
        let offset = AstrologyTestSupport.forwardArc(
            vehlow.cusps[0].eclipticLongitude,
            vehlow.angles.ascendant
        )
        #expect(abs(offset - 15.0) < 1e-9)

        let wholeSign = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .wholeSign
        )
        for cusp in wholeSign.cusps {
            #expect(abs(cusp.degreeInSign) < 1e-9)
        }
        #expect(
            wholeSign.cusps[0].sign
                == ZodiacMapper.details(
                    forNormalizedLongitude: wholeSign.angles.ascendant
                ).sign
        )
    }

    @Test func porphyryAndSripatiMaintainTheirRelationships() throws {
        let fixture = try AstrologyTestSupport.paris1995()
        let porphyry = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .porphyry
        )
        let sripati = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .sripati
        )

        AstrologyTestSupport.expectCircularlyEqual(
            porphyry.cusps[0].eclipticLongitude,
            porphyry.angles.ascendant,
            tolerance: 1e-9
        )
        AstrologyTestSupport.expectCircularlyEqual(
            porphyry.cusps[3].eclipticLongitude,
            porphyry.angles.imumCoeli,
            tolerance: 1e-9
        )
        AstrologyTestSupport.expectCircularlyEqual(
            porphyry.cusps[6].eclipticLongitude,
            porphyry.angles.descendant,
            tolerance: 1e-9
        )
        AstrologyTestSupport.expectCircularlyEqual(
            porphyry.cusps[9].eclipticLongitude,
            porphyry.angles.midheaven,
            tolerance: 1e-9
        )

        let quadrants: [Range<Int>] = [0..<3, 3..<6, 6..<9, 9..<12]
        for quadrant in quadrants {
            let c0 = porphyry.cusps[quadrant.lowerBound].eclipticLongitude
            let c1 = porphyry.cusps[quadrant.lowerBound + 1].eclipticLongitude
            let c2 = porphyry.cusps[quadrant.lowerBound + 2].eclipticLongitude
            let c3 = porphyry.cusps[quadrant.upperBound % 12].eclipticLongitude
            let arc1 = AstrologyTestSupport.forwardArc(c0, c1)
            let arc2 = AstrologyTestSupport.forwardArc(c1, c2)
            let arc3 = AstrologyTestSupport.forwardArc(c2, c3)
            #expect(abs(arc1 - arc2) < 1e-9)
            #expect(abs(arc2 - arc3) < 1e-9)
        }

        for index in 0..<12 {
            let start = porphyry.cusps[(index + 11) % 12].eclipticLongitude
            let end = porphyry.cusps[index].eclipticLongitude
            let midpoint = AngleMath.normalized(
                degrees: start + AstrologyTestSupport.forwardArc(start, end) / 2.0
            )
            AstrologyTestSupport.expectCircularlyEqual(
                sripati.cusps[index].eclipticLongitude,
                midpoint,
                tolerance: 1e-9
            )
        }
    }

    @Test func angleAlignedSystemsKeepCardinalCuspsOnAngles() throws {
        let fixture = try AstrologyTestSupport.paris1995()

        for system in angleAlignedSystems {
            let result = try AstrologyCalculator.houses(
                for: fixture.moment,
                coordinate: fixture.coordinate,
                system: system
            )
            AstrologyTestSupport.expectCircularlyEqual(
                result.cusps[0].eclipticLongitude,
                result.angles.ascendant,
                tolerance: 1e-7,
                "\(system) cusp 1"
            )
            AstrologyTestSupport.expectCircularlyEqual(
                result.cusps[3].eclipticLongitude,
                result.angles.imumCoeli,
                tolerance: 1e-7,
                "\(system) cusp 4"
            )
            AstrologyTestSupport.expectCircularlyEqual(
                result.cusps[6].eclipticLongitude,
                result.angles.descendant,
                tolerance: 1e-7,
                "\(system) cusp 7"
            )
            AstrologyTestSupport.expectCircularlyEqual(
                result.cusps[9].eclipticLongitude,
                result.angles.midheaven,
                tolerance: 1e-7,
                "\(system) cusp 10"
            )

            for index in 0..<6 {
                let opposite = AstrologyTestSupport.forwardArc(
                    result.cusps[index].eclipticLongitude,
                    result.cusps[index + 6].eclipticLongitude
                )
                #expect(abs(opposite - 180.0) < 1e-7)
            }

            AstrologyTestSupport.expectCuspPartition(result.cusps)
        }
    }

    @Test func meridianAndMorinusKeepTheirDistinctGeometry() throws {
        let fixture = try AstrologyTestSupport.paris1995()

        let meridian = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .meridian
        )
        let morinus = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .morinus
        )

        AstrologyTestSupport.expectCuspPartition(meridian.cusps)
        AstrologyTestSupport.expectCuspPartition(morinus.cusps)
        AstrologyTestSupport.expectCircularlyEqual(
            meridian.cusps[9].eclipticLongitude,
            meridian.angles.midheaven,
            tolerance: 1e-7
        )
        #expect(
            AstrologyTestSupport.circularDifference(
                meridian.cusps[0].eclipticLongitude,
                meridian.angles.ascendant
            ) > 1.0
        )
        #expect(
            AstrologyTestSupport.circularDifference(
                morinus.cusps[0].eclipticLongitude,
                morinus.angles.ascendant
            ) > 1.0
        )
        #expect(
            AstrologyTestSupport.circularDifference(
                morinus.cusps[9].eclipticLongitude,
                morinus.angles.midheaven
            ) > 0.1
        )
    }

    @Test func horizontalUsesEastPointVertexAndMeridianAxes() throws {
        let fixture = try AstrologyTestSupport.paris1995()
        let horizontal = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .horizontal
        )

        let antivertex = AngleMath.normalized(
            degrees: (horizontal.angles.vertex ?? .nan) + 180.0
        )
        AstrologyTestSupport.expectCircularlyEqual(
            horizontal.cusps[0].eclipticLongitude,
            antivertex,
            tolerance: 1e-7,
            "horizontal cusp 1"
        )
        AstrologyTestSupport.expectCircularlyEqual(
            horizontal.cusps[3].eclipticLongitude,
            horizontal.angles.imumCoeli,
            tolerance: 1e-7,
            "horizontal cusp 4"
        )
        AstrologyTestSupport.expectCircularlyEqual(
            horizontal.cusps[6].eclipticLongitude,
            horizontal.angles.vertex ?? .nan,
            tolerance: 1e-7,
            "horizontal cusp 7"
        )
        AstrologyTestSupport.expectCircularlyEqual(
            horizontal.cusps[9].eclipticLongitude,
            horizontal.angles.midheaven,
            tolerance: 1e-7,
            "horizontal cusp 10"
        )
        AstrologyTestSupport.expectCuspPartition(horizontal.cusps)
    }

    @Test func horizontalMatchesReferenceFixture() throws {
        let fixture = try AstrologyTestSupport.paris1995()
        let horizontal = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .horizontal
        )

        for (index, expected) in parisHorizontalCusps.enumerated() {
            AstrologyTestSupport.expectCircularlyEqual(
                horizontal.cusps[index].eclipticLongitude,
                expected,
                tolerance: 3e-5,
                "horizontal cusp \(index + 1)"
            )
        }
    }

    @Test func carterUsesAscendantAnchoredRightAscensionGrid() throws {
        let fixture = try AstrologyTestSupport.paris1995()
        let carter = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .carter
        )
        let obliquity = fixture.moment.trueObliquity

        AstrologyTestSupport.expectCircularlyEqual(
            carter.cusps[0].eclipticLongitude,
            carter.angles.ascendant,
            tolerance: 1e-9
        )
        AstrologyTestSupport.expectCircularlyEqual(
            carter.cusps[6].eclipticLongitude,
            carter.angles.descendant,
            tolerance: 1e-9
        )
        #expect(
            AstrologyTestSupport.circularDifference(
                carter.cusps[9].eclipticLongitude,
                carter.angles.midheaven
            ) > 1.0
        )

        let baseRightAscension = AstrologyTestSupport.rightAscensionOnEcliptic(
            longitude: carter.cusps[0].eclipticLongitude,
            obliquity: obliquity
        )
        for index in 1..<12 {
            let rightAscension = AstrologyTestSupport.rightAscensionOnEcliptic(
                longitude: carter.cusps[index].eclipticLongitude,
                obliquity: obliquity
            )
            AstrologyTestSupport.expectCircularlyEqual(
                rightAscension,
                baseRightAscension + 30.0 * Double(index),
                tolerance: 1e-7,
                "carter RA step \(index + 1)"
            )
        }
    }

    @Test func carterMatchesReferenceFixture() throws {
        let fixture = try AstrologyTestSupport.paris1995()
        let carter = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .carter
        )

        for (index, expected) in parisCarterCusps.enumerated() {
            AstrologyTestSupport.expectCircularlyEqual(
                carter.cusps[index].eclipticLongitude,
                expected,
                tolerance: 3e-5,
                "carter cusp \(index + 1)"
            )
        }
    }

    @Test func meridianMatchesAxialRotationReferenceFixture() throws {
        let fixture = try AstrologyTestSupport.paris1995()
        let meridian = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .meridian
        )

        for (index, expected) in parisMeridianCusps.enumerated() {
            AstrologyTestSupport.expectCircularlyEqual(
                meridian.cusps[index].eclipticLongitude,
                expected,
                tolerance: 3e-5,
                "meridian cusp \(index + 1)"
            )
        }
    }

    @Test func topocentricTracksPlacidusAndProjectionSystemsStayDistinct() throws {
        let fixture = try AstrologyTestSupport.paris1995()
        let topocentric = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .topocentric
        )
        let placidus = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .placidus
        )
        let campanus = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .campanus
        )
        let regiomontanus = try AstrologyCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .regiomontanus
        )

        for index in [10, 11, 1, 2] {
            let difference = AstrologyTestSupport.circularDifference(
                topocentric.cusps[index].eclipticLongitude,
                placidus.cusps[index].eclipticLongitude
            )
            #expect(difference < 1.0)
        }

        var maxDifference = 0.0
        for index in [1, 2, 4, 5, 7, 8, 10, 11] {
            maxDifference = max(
                maxDifference,
                AstrologyTestSupport.circularDifference(
                    campanus.cusps[index].eclipticLongitude,
                    regiomontanus.cusps[index].eclipticLongitude
                )
            )
        }
        #expect(maxDifference > 0.1)
    }

    @Test func semiArcSystemsFallbackOrThrowNearPolarLatitudes() throws {
        let moment = try CivilMoment(
            year: 2000,
            month: 6,
            day: 21,
            hour: 12,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coordinate = try GeoCoordinate(latitude: 75.0, longitude: 0.0)

        let placidus = try AstrologyCalculator.houses(
            for: moment,
            coordinate: coordinate,
            system: .placidus,
            polarFallback: .equalASC
        )
        #expect(placidus.resolvedSystem == .equalASC)
        #expect(!placidus.usedRequestedSystem)

        let koch = try AstrologyCalculator.houses(
            for: moment,
            coordinate: coordinate,
            system: .koch,
            polarFallback: .wholeSign
        )
        #expect(koch.resolvedSystem == .wholeSign)

        let alcabitius = try AstrologyCalculator.houses(
            for: moment,
            coordinate: coordinate,
            system: .alcabitius,
            polarFallback: .porphyry
        )
        #expect(alcabitius.resolvedSystem == .porphyry)

        #expect(throws: AstrologyError.houseSystemUndefinedAtLatitude(
            system: .placidus,
            latitude: 75.0
        )) {
            _ = try AstrologyCalculator.houses(
                for: moment,
                coordinate: coordinate,
                system: .placidus,
                polarFallback: .error
            )
        }

        let topocentric = try AstrologyCalculator.houses(
            for: moment,
            coordinate: coordinate,
            system: .topocentric
        )
        #expect(topocentric.resolvedSystem == .topocentric)
    }

    @Test func housesRejectAscendantExtremeLatitude() throws {
        let moment = try CivilMoment(
            year: 2000,
            month: 6,
            day: 21,
            hour: 12,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coordinate = try GeoCoordinate(latitude: 85.1, longitude: 0.0)

        #expect(throws: AstrologyError.core(.extremeLatitude)) {
            _ = try AstrologyCalculator.houses(
                for: moment,
                coordinate: coordinate,
                system: .wholeSign
            )
        }
    }

    @Test func gauquelinUsesIndependentClockwiseSectorModel() throws {
        let fixture = try AstrologyTestSupport.paris1995()
        let sectors = try AstrologyCalculator.gauquelinSectors(
            for: fixture.moment,
            coordinate: fixture.coordinate
        )

        AstrologyTestSupport.expectValidGauquelinSectors(sectors.sectors)
        AstrologyTestSupport.expectClockwiseSectorPartition(sectors.sectors)
        AstrologyTestSupport.expectCircularlyEqual(
            sectors.sectors[0].eclipticLongitude,
            sectors.angles.ascendant,
            tolerance: 1e-9
        )
        AstrologyTestSupport.expectCircularlyEqual(
            sectors.sectors[9].eclipticLongitude,
            sectors.angles.midheaven,
            tolerance: 1e-9
        )
        AstrologyTestSupport.expectCircularlyEqual(
            sectors.sectors[18].eclipticLongitude,
            sectors.angles.descendant,
            tolerance: 1e-9
        )
        AstrologyTestSupport.expectCircularlyEqual(
            sectors.sectors[27].eclipticLongitude,
            sectors.angles.imumCoeli,
            tolerance: 1e-9
        )
    }

    @Test func gauquelinMatchesReferenceFixture() throws {
        let fixture = try AstrologyTestSupport.paris1995()
        let sectors = try AstrologyCalculator.gauquelinSectors(
            for: fixture.moment,
            coordinate: fixture.coordinate
        )

        for (index, expected) in parisGauquelinSectors.enumerated() {
            AstrologyTestSupport.expectCircularlyEqual(
                sectors.sectors[index].eclipticLongitude,
                expected,
                tolerance: 3e-5,
                "gauquelin sector \(index + 1)"
            )
        }
    }
}
