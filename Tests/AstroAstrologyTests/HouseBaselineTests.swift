@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

@Suite("House Baselines")
struct HouseBaselineTests {
    @Test func implementedHouseSystemsMatchBaselinesWhenEnabled() throws {
        guard ProcessInfo.processInfo.environment["ASTROCORE_ENABLE_BASELINE_VERIFICATION"] == "1" else {
            return
        }

        let fixtures = try [
            AstrologyTestSupport.newYork1990(),
            AstrologyTestSupport.london2000(),
            AstrologyTestSupport.paris1995(),
            AstrologyTestSupport.sydney2010()
        ]
        let snapshots = try AstrologyTestSupport.referenceHouseSnapshots(
            fixtures: fixtures,
            systems: HouseSystem.allCases,
            includeGauquelin: true
        )

        for fixture in fixtures {
            guard let snapshot = snapshots[fixture.name] else {
                Issue.record("Missing reference snapshot for \(fixture.name)")
                continue
            }

            for system in HouseSystem.allCases {
                guard let expected = snapshot.systems[
                    AstrologyTestSupport.referenceSystemCode(for: system)
                ] else {
                    Issue.record("Missing reference data for \(system) at \(fixture.name)")
                    continue
                }

                let result = try AstrologyCalculator.houses(
                    for: fixture.moment,
                    coordinate: fixture.coordinate,
                    system: system
                )
                for (index, cusp) in result.cusps.enumerated() {
                    AstrologyTestSupport.expectCircularlyEqual(
                        cusp.eclipticLongitude,
                        expected[index],
                        tolerance: 3e-5,
                        "\(fixture.name) \(system.displayName) cusp \(index + 1)"
                    )
                }
            }

            guard let expectedSectors = snapshot.gauquelin else {
                Issue.record("Missing Gauquelin data for \(fixture.name)")
                continue
            }
            let gauquelin = try AstrologyCalculator.gauquelinSectors(
                for: fixture.moment,
                coordinate: fixture.coordinate
            )
            for (index, sector) in gauquelin.sectors.enumerated() {
                AstrologyTestSupport.expectCircularlyEqual(
                    sector.eclipticLongitude,
                    expectedSectors[index],
                    tolerance: 3e-5,
                    "\(fixture.name) Gauquelin sector \(index + 1)"
                )
            }
        }
    }
}
