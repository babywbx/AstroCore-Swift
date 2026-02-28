// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AstroCore",
    platforms: [
        .iOS(.v15), .macOS(.v12), .tvOS(.v15),
        .watchOS(.v8), .visionOS(.v1),
    ],
    products: [
        .library(name: "AstroCore", targets: ["AstroCore"]),
        .library(name: "AstroCoreLocations", targets: ["AstroCoreLocations"]),
    ],
    targets: [
        .target(name: "AstroCore"),
        .target(
            name: "AstroCoreLocations",
            dependencies: ["AstroCore"],
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "AstroDataGen",
            dependencies: ["AstroCoreLocations"]
        ),
        .testTarget(name: "AstroCoreTests", dependencies: ["AstroCore"]),
        .testTarget(
            name: "AstroCoreLocationsTests",
            dependencies: ["AstroCoreLocations"]
        ),
    ]
)
