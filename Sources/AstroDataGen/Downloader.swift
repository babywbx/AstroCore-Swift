import CryptoKit
import Foundation

enum Downloader {
    static func download(
        url: URL,
        to destination: URL,
        skipIfExists: Bool,
        expectedSHA256: String
    ) async throws {
        if skipIfExists && FileManager.default.fileExists(atPath: destination.path) {
            try verifySHA256(of: destination, expected: expectedSHA256)
            print("  Cached: \(destination.lastPathComponent) (checksum verified)")
            return
        }
        print("  Downloading \(url.lastPathComponent)...")
        let (tempURL, response) = try await URLSession.shared.download(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            try? FileManager.default.removeItem(at: tempURL)
            throw DataGenError.downloadFailed(url: url)
        }
        do {
            try verifySHA256(of: tempURL, expected: expectedSHA256)
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            throw error
        }
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempURL, to: destination)
        print("  Done: \(destination.lastPathComponent)")
    }

    private static func verifySHA256(of file: URL, expected: String) throws {
        let actual = try sha256HexDigest(of: file)
        guard actual == expected.lowercased() else {
            throw DataGenError.checksumMismatch(
                file: file,
                expected: expected.lowercased(),
                actual: actual
            )
        }
    }

    private static func sha256HexDigest(of file: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }

        var hasher = SHA256()
        while true {
            let data = try handle.read(upToCount: 1024 * 1024) ?? Data()
            guard !data.isEmpty else { break }
            hasher.update(data: data)
        }
        return hasher.finalize()
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
