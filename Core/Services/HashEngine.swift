import Foundation
import CryptoKit

/// Engine responsible for generating deterministic SHA-256 hashes.
/// This is used to ensure the immutability and integrity of network test evidence.
final class HashEngine {

    /// Generates a SHA-256 hash from a given string.
    /// - Parameter text: The string content to hash.
    /// - Returns: A hex-encoded SHA-256 hash string.
    static func sha256(from text: String) -> String {
        let data = Data(text.utf8)
        return sha256(from: data)
    }

    /// Generates a SHA-256 hash from Data.
    /// Primarily used for PDF payload and raw evidence verification.
    /// - Parameter data: The data to hash.
    /// - Returns: A hex-encoded SHA-256 hash string.
    static func sha256(from data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    /// Generates a deterministic SHA-256 hash from a `NetworkTestResult`.
    /// This hash encodes critical evidence fields: timestamp, configuration, metrics, context, and ID.
    /// Changing any value in the input will produce a different hash, ensuring data integrity.
    /// - Parameter result: The `NetworkTestResult` to process.
    /// - Returns: A hex-encoded SHA-256 string unique to this specific test result.
    static func hash(from result: NetworkTestResult) -> String {
        var source = ""

        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: result.timestamp)

        // Canonical string representation of the test result
        source += "ID=\(result.id.uuidString)\n"
        source += "DATE=\(dateString)\n"
        source += "TARGET=\(result.config.targetURL.absoluteString)\n"
        source += "MODE=\(result.config.mode.rawValue)\n"
        source += "SAMPLES=\(result.config.sampleCount)\n"
        source += "INTERVAL_MS=\(result.config.intervalMs)\n"
        source += "TIMEOUT_S=\(result.config.timeoutSeconds)\n"
        source += "AVG=\(result.avgLatencyMs)\n"
        source += "MIN=\(result.minLatencyMs)\n"
        source += "MAX=\(result.maxLatencyMs)\n"
        source += "JITTER=\(result.jitterMs)\n"
        source += "LOSS=\(result.packetLossPercent)\n"
        source += "SCORE=\(result.stabilityScore)\n"
        source += "TAG=\(result.stabilityStatus.rawValue)\n"
        source += "NETWORK_TYPE=\(result.networkContext.connectionType.rawValue)\n"

        return sha256(from: source)
    }
}
