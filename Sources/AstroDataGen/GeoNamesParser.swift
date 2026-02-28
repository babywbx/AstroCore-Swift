import Foundation

enum GeoNamesParser {
    private typealias CityRow = [Any]

    /// Parse GeoNames cities15000.txt (TSV) and generate cities.json
    static func parse(input: URL, output: URL) throws {
        let content = try String(contentsOf: input, encoding: .utf8)
        var cities: [(population: Int, row: CityRow)] = []

        for line in content.components(separatedBy: .newlines) {
            let fields = line.components(separatedBy: "\t")
            guard fields.count >= 18 else { continue }

            let id = fields[0]
            let name = fields[1]
            guard let latitude = Double(fields[4]),
                let longitude = Double(fields[5])
            else { continue }
            let countryCode = fields[8]
            let population = Int(fields[14]) ?? 0
            let timezone = fields[17]

            // Validate coordinate ranges
            guard (-90.0...90.0).contains(latitude),
                (-180.0...180.0).contains(longitude),
                !timezone.isEmpty
            else { continue }

            let cityRow: CityRow = [
                id,
                name,
                countryCode,
                Int((latitude * 100_000.0).rounded()),
                Int((longitude * 100_000.0).rounded()),
                timezone,
            ]
            cities.append((population: population, row: cityRow))
        }

        // Sort by population descending
        cities.sort {
            $0.population > $1.population
        }

        let data = try JSONSerialization.data(
            withJSONObject: cities.map(\.row)
        )
        try data.write(to: output, options: .atomic)
        print("  Wrote \(cities.count) cities to cities.json")
    }
}
