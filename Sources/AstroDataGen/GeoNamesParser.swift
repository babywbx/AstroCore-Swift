import Foundation

enum GeoNamesParser {
    /// Parse GeoNames cities15000.txt (TSV) and generate cities.json
    static func parse(input: URL, output: URL) throws {
        let content = try String(contentsOf: input, encoding: .utf8)
        var cities: [[String: Any]] = []

        for line in content.components(separatedBy: .newlines) {
            let fields = line.components(separatedBy: "\t")
            guard fields.count >= 18 else { continue }

            let id = fields[0]
            let name = fields[1]
            let alternateNames = fields[3]
            guard let latitude = Double(fields[4]),
                let longitude = Double(fields[5])
            else { continue }
            let countryCode = fields[8]
            let admin1 = fields[10]
            let population = Int(fields[14]) ?? 0
            let timezone = fields[17]

            // Validate coordinate ranges
            guard (-90.0...90.0).contains(latitude),
                (-180.0...180.0).contains(longitude),
                !timezone.isEmpty
            else { continue }

            // Extract localized name (Chinese preferred, fallback to alternates)
            let localizedName = extractLocalizedName(from: alternateNames)

            var city: [String: Any] = [
                "id": id,
                "name": name,
                "countryCode": countryCode,
                "latitude": latitude,
                "longitude": longitude,
                "timeZoneIdentifier": timezone,
                "population": population,
            ]
            if let ln = localizedName {
                city["localizedName"] = ln
            }
            if !admin1.isEmpty {
                city["admin1"] = admin1
            }
            cities.append(city)
        }

        // Sort by population descending
        cities.sort {
            ($0["population"] as? Int ?? 0) > ($1["population"] as? Int ?? 0)
        }

        let data = try JSONSerialization.data(
            withJSONObject: cities,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: output, options: .atomic)
        print("  Wrote \(cities.count) cities to cities.json")
    }

    /// Extract localized name from comma-separated alternate names.
    /// Prefers Chinese, falls back to first non-ASCII name.
    private static func extractLocalizedName(from alternates: String) -> String? {
        guard !alternates.isEmpty else { return nil }
        let names = alternates.components(separatedBy: ",")

        // Prefer Chinese characters
        for name in names {
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            if trimmed.unicodeScalars.contains(where: { $0.value >= 0x4E00 && $0.value <= 0x9FFF }) {
                return trimmed
            }
        }

        // Fallback to first non-ASCII name
        for name in names {
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.canBeConverted(to: .ascii) {
                return trimmed
            }
        }
        return nil
    }
}
