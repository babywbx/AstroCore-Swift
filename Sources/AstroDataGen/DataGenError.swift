import Foundation

enum DataGenError: Error, CustomStringConvertible {
    case downloadFailed(url: URL)
    case unzipFailed(file: URL)
    case parseFailed(detail: String)
    case invalidData(detail: String)
    case packageRootNotFound

    var description: String {
        switch self {
        case .downloadFailed(let url): "Download failed: \(url)"
        case .unzipFailed(let file): "Unzip failed: \(file)"
        case .parseFailed(let detail): "Parse failed: \(detail)"
        case .invalidData(let detail): "Invalid data: \(detail)"
        case .packageRootNotFound: "Could not find Package.swift in parent directories"
        }
    }
}
