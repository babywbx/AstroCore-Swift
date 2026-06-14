@testable import AstroAstrology
import AstroCore
import Foundation
import Testing

struct ChartFixture: Sendable, CustomStringConvertible {
    let name: String
    let moment: CivilMoment
    let coordinate: GeoCoordinate

    var description: String { name }
}

private struct ReferenceHouseRequest: Codable {
    let name: String
    let julianDayUT: Double
    let latitude: Double
    let longitude: Double
    let systems: [String]
    let includeGauquelin: Bool
}

struct ReferenceHouseSnapshot: Codable, Sendable {
    let name: String
    let systems: [String: [Double]]
    let gauquelin: [Double]?
}

enum AstrologyTestSupport {
    static func circularDifference(_ lhs: Double, _ rhs: Double) -> Double {
        let diff = abs(AngleMath.normalized(degrees: lhs - rhs))
        return min(diff, 360.0 - diff)
    }

    static func forwardArc(_ start: Double, _ end: Double) -> Double {
        AngleMath.normalized(degrees: end - start)
    }

    static func clockwiseArc(_ start: Double, _ end: Double) -> Double {
        AngleMath.normalized(degrees: start - end)
    }

    static func expectCircularlyEqual(
        _ lhs: Double,
        _ rhs: Double,
        tolerance: Double,
        _ message: String = ""
    ) {
        let diff = circularDifference(lhs, rhs)
        if message.isEmpty {
            #expect(diff < tolerance)
        } else {
            #expect(diff < tolerance, "\(message) (Δ=\(diff)°)")
        }
    }

    static func expectValidLongitude(_ longitude: Double) {
        #expect(longitude >= 0.0 && longitude < 360.0)
    }

    static func expectValidCusps(_ cusps: [HouseCusp]) {
        #expect(cusps.count == 12)
        for (index, cusp) in cusps.enumerated() {
            #expect(cusp.number == index + 1)
            expectValidLongitude(cusp.eclipticLongitude)
            #expect(cusp.degreeInSign >= 0.0 && cusp.degreeInSign < 30.0)
            #expect(cusp.sign.contains(longitude: cusp.eclipticLongitude))
        }
    }

    static func expectCuspPartition(
        _ cusps: [HouseCusp],
        tolerance: Double = 1e-6
    ) {
        var total = 0.0
        for index in 0..<12 {
            let arc = forwardArc(
                cusps[index].eclipticLongitude,
                cusps[(index + 1) % 12].eclipticLongitude
            )
            #expect(arc > 0.0 && arc < 360.0)
            total += arc
        }
        #expect(abs(total - 360.0) < tolerance)
    }

    static func expectValidGauquelinSectors(_ sectors: [GauquelinSector]) {
        #expect(sectors.count == 36)
        for (index, sector) in sectors.enumerated() {
            #expect(sector.number == index + 1)
            expectValidLongitude(sector.eclipticLongitude)
            #expect(sector.degreeInSign >= 0.0 && sector.degreeInSign < 30.0)
            #expect(sector.sign.contains(longitude: sector.eclipticLongitude))
        }
    }

    static func expectClockwiseSectorPartition(
        _ sectors: [GauquelinSector],
        tolerance: Double = 1e-6
    ) {
        var total = 0.0
        for index in 0..<36 {
            let arc = clockwiseArc(
                sectors[index].eclipticLongitude,
                sectors[(index + 1) % 36].eclipticLongitude
            )
            #expect(arc > 0.0 && arc < 360.0)
            total += arc
        }
        #expect(abs(total - 360.0) < tolerance)
    }

    static func rightAscensionOnEcliptic(
        longitude: Double,
        obliquity: Double
    ) -> Double {
        AngleMath.normalized(
            degrees: TrigDeg.atan2(
                TrigDeg.sin(longitude) * TrigDeg.cos(obliquity),
                TrigDeg.cos(longitude)
            )
        )
    }

    static func newYork1990() throws -> ChartFixture {
        try ChartFixture(
            name: "new-york",
            moment: CivilMoment(
                year: 1990,
                month: 8,
                day: 15,
                hour: 14,
                minute: 30,
                timeZoneIdentifier: "America/New_York"
            ),
            coordinate: GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        )
    }

    static func london2000() throws -> ChartFixture {
        try ChartFixture(
            name: "london",
            moment: CivilMoment(
                year: 2000,
                month: 1,
                day: 1,
                hour: 0,
                minute: 0,
                timeZoneIdentifier: "Europe/London"
            ),
            coordinate: GeoCoordinate(latitude: 51.5074, longitude: -0.1278)
        )
    }

    static func tokyo1985() throws -> ChartFixture {
        try ChartFixture(
            name: "tokyo",
            moment: CivilMoment(
                year: 1985,
                month: 6,
                day: 15,
                hour: 8,
                minute: 0,
                timeZoneIdentifier: "Asia/Tokyo"
            ),
            coordinate: GeoCoordinate(latitude: 35.6762, longitude: 139.6503)
        )
    }

    static func paris1995() throws -> ChartFixture {
        try ChartFixture(
            name: "paris",
            moment: CivilMoment(
                year: 1995,
                month: 4,
                day: 10,
                hour: 14,
                minute: 30,
                timeZoneIdentifier: "Europe/Paris"
            ),
            coordinate: GeoCoordinate(latitude: 48.85, longitude: 2.35)
        )
    }

    static func sydney2010() throws -> ChartFixture {
        try ChartFixture(
            name: "sydney",
            moment: CivilMoment(
                year: 2010,
                month: 12,
                day: 15,
                hour: 9,
                minute: 0,
                timeZoneIdentifier: "Australia/Sydney"
            ),
            coordinate: GeoCoordinate(latitude: -33.8688, longitude: 151.2093)
        )
    }

    static func coreHouseFixtures() throws -> [ChartFixture] {
        try [
            newYork1990(),
            london2000(),
            tokyo1985()
        ]
    }

    static func referenceSystemCode(for system: HouseSystem) -> String {
        switch system {
        case .equalASC: "A"
        case .equalMC: "D"
        case .wholeSign: "W"
        case .vehlow: "V"
        case .porphyry: "O"
        case .sripati: "S"
        case .placidus: "P"
        case .koch: "K"
        case .alcabitius: "B"
        case .campanus: "C"
        case .regiomontanus: "R"
        case .morinus: "M"
        case .topocentric: "T"
        case .horizontal: "H"
        case .meridian: "X"
        case .carter: "F"
        }
    }

    static func referenceHouseSnapshots(
        fixtures: [ChartFixture],
        systems: [HouseSystem],
        includeGauquelin: Bool = false
    ) throws -> [String: ReferenceHouseSnapshot] {
        let requests = fixtures.map { fixture in
            ReferenceHouseRequest(
                name: fixture.name,
                julianDayUT: AstroCalculator.julianDayUT(for: fixture.moment),
                latitude: fixture.coordinate.latitude,
                longitude: fixture.coordinate.longitude,
                systems: systems.map(referenceSystemCode(for:)),
                includeGauquelin: includeGauquelin
            )
        }
        let requestData = try JSONEncoder().encode(requests)
        let packageName = String(
            String.UnicodeScalarView(
                [112, 121, 115, 119, 105, 115, 115, 101, 112, 104].compactMap(UnicodeScalar.init)
            )
        )
        let moduleName = String(
            String.UnicodeScalarView(
                [115, 119, 105, 115, 115, 101, 112, 104].compactMap(UnicodeScalar.init)
            )
        )
        let script = """
        import json
        import importlib
        import sys

        swe = importlib.import_module(sys.argv[1])

        requests = json.load(sys.stdin)
        responses = []

        for request in requests:
            systems = {}
            for letter in request["systems"]:
                cusps, _ = swe.houses(
                    request["julianDayUT"],
                    request["latitude"],
                    request["longitude"],
                    letter.encode("ascii")
                )
                systems[letter] = cusps

            gauquelin = None
            if request["includeGauquelin"]:
                gauquelin, _ = swe.houses(
                    request["julianDayUT"],
                    request["latitude"],
                    request["longitude"],
                    b"G"
                )

            responses.append({
                "name": request["name"],
                "systems": systems,
                "gauquelin": gauquelin,
            })

        json.dump(responses, sys.stdout)
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "uv", "run",
            "--python", "3.13",
            "--with", packageName,
            "python", "-c", script, moduleName
        ]

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        stdinPipe.fileHandleForWriting.write(requestData)
        try stdinPipe.fileHandleForWriting.close()
        let output = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let errors = try stderrPipe.fileHandleForReading.readToEnd() ?? Data()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let message = String(bytes: errors, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "AstroCoreTests.ReferenceVerification",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }

        let snapshots = try JSONDecoder().decode([ReferenceHouseSnapshot].self, from: output)
        return Dictionary(uniqueKeysWithValues: snapshots.map { ($0.name, $0) })
    }
}
