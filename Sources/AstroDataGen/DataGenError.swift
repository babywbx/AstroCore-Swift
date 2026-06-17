import Foundation

enum DataGenError: Error, CustomStringConvertible {
    case downloadFailed(url: URL)
    case checksumMismatch(file: URL, expected: String, actual: String)
    case unzipFailed(file: URL)
    case parseFailed(detail: String)
    case invalidData(detail: String)
    case unsupportedPlatform(detail: String)
    case insecureURL(String, URL)
    case missingEnvironmentValue(String)
    case missingEnvironmentURL(String)
    case invalidEnvironmentURL(String, String)
    case packageRootNotFound

    var description: String {
        switch self {
        case .downloadFailed(let url): "Download failed: \(url)"
        case .checksumMismatch(let file, let expected, let actual):
            "Checksum mismatch for \(file.path): expected \(expected), got \(actual)"
        case .unzipFailed(let file): "Unzip failed: \(file)"
        case .parseFailed(let detail): "Parse failed: \(detail)"
        case .invalidData(let detail): "Invalid data: \(detail)"
        case .unsupportedPlatform(let detail): "Unsupported platform: \(detail)"
        case .insecureURL(let key, let url): "Insecure URL in \(key): \(url)"
        case .missingEnvironmentValue(let key): "Missing required environment variable: \(key)"
        case .missingEnvironmentURL(let key): "Missing required environment variable: \(key)"
        case .invalidEnvironmentURL(let key, let value): "Invalid URL in \(key): \(value)"
        case .packageRootNotFound: "Could not find Package.swift in parent directories"
        }
    }
}
