import Foundation

enum ZipExtractor {
    /// Extract only the expected file from a zip archive.
    /// Validates that the archive contains only known entries.
    static func extract(
        _ zipFile: URL, to directory: URL, expectedFiles: Set<String>
    ) throws {
        #if os(macOS)
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )

            // List raw archive entries first.
            let listProcess = Process()
            listProcess.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            listProcess.arguments = ["-Z1", zipFile.path]
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

            let entries = Set(
                listOutput.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
            guard entries == expectedFiles else {
                throw DataGenError.invalidData(
                    detail: "Zip entries \(entries.sorted()) do not match expected \(expectedFiles.sorted())"
                )
            }

            for entry in entries {
                let components = entry.split(separator: "/")
                if entry.hasPrefix("/")
                    || entry.hasSuffix("/")
                    || components.isEmpty
                    || components.contains("..")
                {
                    throw DataGenError.invalidData(
                        detail: "Zip contains suspicious path: \(entry)"
                    )
                }
            }

            // Extract only expected files
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            process.arguments = ["-o", zipFile.path]
                + expectedFiles.sorted()
                + ["-d", directory.path]
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
                let values = try path.resourceValues(forKeys: [
                    .fileSizeKey,
                    .isRegularFileKey,
                    .isSymbolicLinkKey
                ])
                guard values.isRegularFile == true,
                      values.isSymbolicLink != true
                else {
                    try? FileManager.default.removeItem(at: path)
                    throw DataGenError.invalidData(
                        detail: "Extracted file \(file) is not a regular file"
                    )
                }
                let size = UInt64(values.fileSize ?? 0)
                if size > maxSize {
                    try? FileManager.default.removeItem(at: path)
                    throw DataGenError.invalidData(
                        detail: "Extracted file \(file) exceeds size limit (\(size) bytes)"
                    )
                }
            }
        #else
            throw DataGenError.unsupportedPlatform(
                detail: "Zip extraction requires Process and is only available on macOS"
            )
        #endif
    }
}
