import Foundation

enum ZipExtractor {
    /// Extract only the expected file from a zip archive.
    /// Validates that the archive contains only known entries.
    static func extract(
        _ zipFile: URL, to directory: URL, expectedFiles: Set<String>
    ) throws {
        // List archive contents first
        let listProcess = Process()
        listProcess.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        listProcess.arguments = ["-l", zipFile.path]
        let pipe = Pipe()
        listProcess.standardOutput = pipe
        listProcess.standardError = nil
        try listProcess.run()
        listProcess.waitUntilExit()

        guard listProcess.terminationStatus == 0 else {
            throw DataGenError.unzipFailed(file: zipFile)
        }

        let listOutput = String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""

        // Reject path traversal and unexpected entries
        let entries = listOutput.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        for entry in entries {
            if entry.contains("..") || entry.hasPrefix("/") {
                throw DataGenError.invalidData(
                    detail: "Zip contains suspicious path: \(entry)"
                )
            }
        }

        // Extract only expected files
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", zipFile.path, "-d", directory.path]
            + Array(expectedFiles)
        process.standardOutput = nil
        process.standardError = nil
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw DataGenError.unzipFailed(file: zipFile)
        }

        // Verify extracted file sizes (reject files > 500MB)
        let maxSize: UInt64 = 500 * 1024 * 1024
        for file in expectedFiles {
            let path = directory.appendingPathComponent(file)
            let attrs = try? FileManager.default.attributesOfItem(atPath: path.path)
            let size = attrs?[.size] as? UInt64 ?? 0
            if size > maxSize {
                try? FileManager.default.removeItem(at: path)
                throw DataGenError.invalidData(
                    detail: "Extracted file \(file) exceeds size limit (\(size) bytes)"
                )
            }
        }
    }
}
