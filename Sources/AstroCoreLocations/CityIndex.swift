import Foundation

// City search index — loads cities.json lazily
// Full implementation in Phase 3
public final class CityIndex: @unchecked Sendable {
    public static let shared = CityIndex()

    private var cities: [CityRecord] = []
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
        cities = decoded
    }

    public func search(_ query: String, limit: Int = 50) -> [CityRecord] {
        ensureLoaded()
        let lowered = query.lowercased()
        let results = cities.filter { city in
            city.name.lowercased().contains(lowered)
                || city.localizedName?.lowercased().contains(lowered) == true
                || city.countryCode.lowercased() == lowered
        }
        return Array(results.prefix(limit))
    }

    public func city(forID id: String) -> CityRecord? {
        ensureLoaded()
        return cities.first { $0.id == id }
    }

    public func popularCities(limit: Int = 20) -> [CityRecord] {
        ensureLoaded()
        return Array(cities.prefix(limit))
    }
}
