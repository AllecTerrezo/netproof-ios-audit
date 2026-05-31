import Foundation

/// Utility for handling temporary file creation and management.
enum TempFileWriter {
    
    /// Writes data to a temporary PDF file.
    /// - Parameters:
    ///   - data: The raw PDF data to be written.
    ///   - filename: The target file name.
    /// - Returns: The URL to the newly created temporary file.
    static func writePDF(data: Data, filename: String) throws -> URL {
        return try write(data: data, filename: filename)
    }

    /// Writes data to a temporary file, replacing existing files with the same name.
    /// - Parameters:
    ///   - data: The raw data to be written.
    ///   - filename: The target file name.
    /// - Returns: The URL to the newly created temporary file.
    static func write(data: Data, filename: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }

        try data.write(to: url, options: [.atomic])
        return url
    }
}
