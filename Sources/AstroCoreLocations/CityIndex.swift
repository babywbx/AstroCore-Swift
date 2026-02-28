import Foundation

// City search index — loads the compact cities.json lazily
public final class CityIndex: @unchecked Sendable {
    private struct SearchEntry {
        let city: CityRecord
        let normalizedName: String
        let normalizedCountryCode: String
    }

    public static let shared = CityIndex()

    private var searchEntries: [SearchEntry] = []
    private var citiesByID: [String: CityRecord] = [:]
    private var isLoaded = false
    private let lock = NSLock()

    private init() {}

    private func ensureLoaded() {
        lock.lock()
        defer { lock.unlock() }
        guard !isLoaded else { return }
        loadCities()
        isLoaded = true
    }

    private func loadCities() {
        guard let url = Bundle.module.url(
            forResource: "cities", withExtension: "json"
        ) else { return }
        guard let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([CityRecord].self, from: data)
        else { return }
        searchEntries = decoded.map { city in
            SearchEntry(
                city: city,
                normalizedName: city.name.lowercased(),
                normalizedCountryCode: city.countryCode.lowercased()
            )
        }
        citiesByID = Dictionary(
            decoded.map { city in (city.id, city) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    public func search(_ query: String, limit: Int = 50) -> [CityRecord] {
        ensureLoaded()
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalizedQuery.isEmpty else { return [] }

        let results = searchEntries.lazy.filter { entry in
            entry.normalizedName.contains(normalizedQuery)
                || entry.normalizedCountryCode == normalizedQuery
        }
        return Array(results.prefix(limit).map(\.city))
    }

    public func city(forID id: String) -> CityRecord? {
        ensureLoaded()
        return citiesByID[id]
    }
}
