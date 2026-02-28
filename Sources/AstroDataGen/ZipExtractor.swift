import Foundation

enum ZipExtractor {
    static func extract(_ zipFile: URL, to directory: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", zipFile.path, "-d", directory.path]
        process.standardOutput = nil
        process.standardError = nil
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw DataGenError.unzipFailed(file: zipFile)
        }
    }
}
