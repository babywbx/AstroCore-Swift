import Foundation

/// City search index — loads the compact cities.json lazily
public final class CityIndex: @unchecked Sendable {
    private enum LoadState {
        case unloaded
        case loaded
        case failed
    }

    private struct SearchEntry {
        let city: CityRecord
        let normalizedName: String
        let normalizedCountryCode: String
    }

    public static let shared = CityIndex()

    private var searchEntries: [SearchEntry] = []
    private var citiesByID: [String: CityRecord] = [:]
    private var loadState = LoadState.unloaded
    private let lock = NSLock()

    private init() {}

    private func ensureLoaded() {
        lock.lock()
        defer { lock.unlock() }
        guard case .unloaded = loadState else { return }

        do {
            try loadCities()
            loadState = .loaded
        } catch {
            searchEntries = []
            citiesByID = [:]
            loadState = .failed
            print("[AstroCoreLocations] Failed to load cities.json: \(error)")
        }
    }

    private func loadCities() throws {
        guard let url = Bundle.module.url(
            forResource: "cities", withExtension: "json"
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([CityRecord].self, from: data)

        searchEntries = decoded.map { city in
            SearchEntry(
                city: city,
                normalizedName: Self.normalizeSearchText(city.name),
                normalizedCountryCode: Self.normalizeSearchText(city.countryCode)
            )
        }
        citiesByID = Dictionary(
            decoded.map { city in (city.id, city) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    public func search(_ query: String, limit: Int = 50) -> [CityRecord] {
        ensureLoaded()
        let normalizedQuery = Self.normalizeSearchText(query)
        guard !normalizedQuery.isEmpty, limit > 0 else { return [] }

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

    private static func normalizeSearchText(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .lowercased()
    }
}
