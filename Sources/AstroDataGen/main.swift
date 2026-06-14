import Foundation

// AstroDataGen — downloads and generates data files for AstroCore

func requiredEnvironmentURL(_ key: String) throws -> URL {
    guard let value = ProcessInfo.processInfo.environment[key],
          !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
        throw DataGenError.missingEnvironmentURL(key)
    }
    guard let url = URL(string: value) else {
        throw DataGenError.invalidEnvironmentURL(key, value)
    }
    return url
}

func findPackageRoot() -> URL {
    var dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    while dir.path != "/" {
        let packageSwift = dir.appendingPathComponent("Package.swift")
        if FileManager.default.fileExists(atPath: packageSwift.path) {
            return dir
        }
        dir = dir.deletingLastPathComponent()
    }
    // Fallback to current directory
    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
}

func planetSwiftName(_ code: String) -> String {
    switch code {
    case "ear": "Earth"
    case "mer": "Mercury"
    case "ven": "Venus"
    case "mar": "Mars"
    case "jup": "Jupiter"
    case "sat": "Saturn"
    case "ura": "Uranus"
    case "nep": "Neptune"
    default: code.capitalized
    }
}

func run() async throws {
    let rootDir = findPackageRoot()
    print("Package root: \(rootDir.path)")

    let cacheDir = rootDir.appendingPathComponent(".data-cache")
    try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

    // --- 1. Download coefficient files ---
    print("\n--- Downloading VSOP87D coefficient files ---")
    let vsopBase = try requiredEnvironmentURL("ASTRO_DATAGEN_VSOP_BASE_URL")
    let bodies = ["ear", "mer", "ven", "mar", "jup", "sat", "ura", "nep"]
    for body in bodies {
        let filename = "VSOP87D.\(body)"
        let url = vsopBase.appendingPathComponent(filename)
        let dest = cacheDir.appendingPathComponent(filename)
        try await Downloader.download(url: url, to: dest, skipIfExists: true)
    }

    // --- 2. Download & extract city dataset ---
    print("\n--- Downloading city dataset ---")
    let cityDataTxt = cacheDir.appendingPathComponent("cities15000.txt")
    if !FileManager.default.fileExists(atPath: cityDataTxt.path) {
        let cityDataZip = cacheDir.appendingPathComponent("cities15000.zip")
        let url = try requiredEnvironmentURL("ASTRO_DATAGEN_CITY_DATA_URL")
        try await Downloader.download(url: url, to: cityDataZip, skipIfExists: false)
        try ZipExtractor.extract(
            cityDataZip, to: cacheDir,
            expectedFiles: ["cities15000.txt"]
        )
        try? FileManager.default.removeItem(at: cityDataZip)
    } else {
        print("  Cached: cities15000.txt")
    }

    // --- 3. Generate VSOP87D Swift files ---
    print("\n--- Generating VSOP87D Swift source files ---")
    let vsopOutputDir = rootDir
        .appendingPathComponent("Sources/AstroCore/Planets/VSOP87DData")
    try FileManager.default.createDirectory(at: vsopOutputDir, withIntermediateDirectories: true)

    for body in bodies {
        let input = cacheDir.appendingPathComponent("VSOP87D.\(body)")
        let swiftName = planetSwiftName(body)
        let output = vsopOutputDir.appendingPathComponent("VSOP87D+\(swiftName).swift")
        try VSOP87DParser.parse(input: input, output: output, planetName: swiftName)
        print("  Generated VSOP87D+\(swiftName).swift")
    }

    // --- 4. Generate cities.json ---
    print("\n--- Generating cities.json ---")
    let citiesOutput = rootDir
        .appendingPathComponent("Sources/AstroCoreLocations/Resources/cities.json")
    try CityDataParser.parse(input: cityDataTxt, output: citiesOutput)

    print("\n✅ All data files generated successfully.")
}

// Entry point
Task {
    do {
        try await run()
        exit(0)
    } catch {
        print("❌ Error: \(error)")
        exit(1)
    }
}

// Keep the process alive for async work
RunLoop.main.run()
