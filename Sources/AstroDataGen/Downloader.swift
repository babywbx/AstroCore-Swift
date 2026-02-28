import Foundation

enum Downloader {
    static func download(url: URL, to destination: URL, skipIfExists: Bool) async throws {
        if skipIfExists && FileManager.default.fileExists(atPath: destination.path) {
            print("  Cached: \(destination.lastPathComponent)")
            return
        }
        print("  Downloading \(url.lastPathComponent)...")
        let (tempURL, response) = try await URLSession.shared.download(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DataGenError.downloadFailed(url: url)
        }
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempURL, to: destination)
        print("  Done: \(destination.lastPathComponent)")
    }
}
