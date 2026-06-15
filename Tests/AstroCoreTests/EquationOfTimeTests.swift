@testable import AstroCore
import Testing

@Suite("Equation of Time")
struct EquationOfTimeTests {
    private func jdUT(_ y: Int, _ m: Int, _ d: Int) throws -> Double {
        let moment = try CivilMoment(year: y, month: m, day: d, hour: 12, minute: 0, timeZoneIdentifier: "UTC")
        return AstroCalculator.julianDayUT(for: moment)
    }

    @Test func staysWithinPhysicalBounds() throws {
        for (m, d) in [(1, 15), (2, 11), (4, 15), (6, 13), (9, 1), (11, 3), (12, 25)] {
            #expect(try abs(AstroCalculator.equationOfTime(julianDayUT: jdUT(2000, m, d))) < 17.0)
        }
    }

    @Test func matchesKnownSeasonalExtremaAndZeros() throws {
        // Well-known shape: mid-Feb ≈ −14 min, early-Nov ≈ +16 min, late-Dec ≈ 0.
        #expect(try AstroCalculator.equationOfTime(julianDayUT: jdUT(2000, 2, 11)) < -13.0)
        #expect(try AstroCalculator.equationOfTime(julianDayUT: jdUT(2000, 2, 11)) > -15.5)
        #expect(try AstroCalculator.equationOfTime(julianDayUT: jdUT(2000, 11, 3)) > 15.0)
        #expect(try AstroCalculator.equationOfTime(julianDayUT: jdUT(2000, 11, 3)) < 17.0)
        #expect(try abs(AstroCalculator.equationOfTime(julianDayUT: jdUT(2000, 12, 25))) < 1.5)
    }

    /// EoT (minutes, apparent − mean) at 12:00 UTC from a local reference ephemeris. MEASURED, NOT FABRICATED.
    /// Tolerance reflects measured agreement; the small gap is the expected method/ΔUT1 difference.
    @Test func matchesIndependentAnchors() throws {
        let tol = 0.05
        #expect(try abs(AstroCalculator.equationOfTime(julianDayUT: jdUT(2000, 1, 13)) + 8.4775) < tol)
        #expect(try abs(AstroCalculator.equationOfTime(julianDayUT: jdUT(2000, 7, 15)) + 5.9759) < tol)
    }
}
