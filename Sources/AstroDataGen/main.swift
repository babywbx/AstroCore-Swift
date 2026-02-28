import Foundation

// AstroDataGen — Downloads and generates all data files for AstroCore

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
    case "ear": return "Earth"
    case "mer": return "Mercury"
    case "ven": return "Venus"
    case "mar": return "Mars"
    case "jup": return "Jupiter"
    case "sat": return "Saturn"
    default: return code.capitalized
    }
}

func run() async throws {
    let rootDir = findPackageRoot()
    print("Package root: \(rootDir.path)")

    let cacheDir = rootDir.appendingPathComponent(".data-cache")
    try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

    // --- 1. Download VSOP87D files ---
    print("\n--- Downloading VSOP87D coefficient files ---")
    let vsopBase = "https://cdsarc.cds.unistra.fr/ftp/cats/VI/81"
    let bodies = ["ear", "mer", "ven", "mar", "jup", "sat"]
    for body in bodies {
        let filename = "VSOP87D.\(body)"
        let url = URL(string: "\(vsopBase)/\(filename)")!
        let dest = cacheDir.appendingPathComponent(filename)
        try await Downloader.download(url: url, to: dest, skipIfExists: true)
    }

    // --- 2. Download & extract GeoNames ---
    print("\n--- Downloading GeoNames cities ---")
    let geonamesTxt = cacheDir.appendingPathComponent("cities15000.txt")
    if !FileManager.default.fileExists(atPath: geonamesTxt.path) {
        let geonamesZip = cacheDir.appendingPathComponent("cities15000.zip")
        let url = URL(string: "https://download.geonames.org/export/dump/cities15000.zip")!
        try await Downloader.download(url: url, to: geonamesZip, skipIfExists: false)
        try ZipExtractor.extract(geonamesZip, to: cacheDir)
        try? FileManager.default.removeItem(at: geonamesZip)
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
    try GeoNamesParser.parse(input: geonamesTxt, output: citiesOutput)

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
