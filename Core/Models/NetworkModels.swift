import Foundation

// MARK: - Test Mode

/// Specifies the operational mode for the network test.
public enum TestMode: String, Codable {
    case single
    case continuous

    public var uiKey: String { "test_mode_\(rawValue)" }
    public var pdfKey: String { "pdf_test_mode_\(rawValue)" }
}

// MARK: - Stability Status

/// Represents the health classification of the network connection.
public enum StabilityStatus: String, Codable {
    case good
    case unstable
    case poor
}

// MARK: - Test Configuration

/// Contains the input parameters for a network audit session.
public struct NetworkTestConfig: Codable {
    public let targetURL: URL
    public let sampleCount: Int
    public let intervalMs: Int
    public let timeoutSeconds: Double
    public let mode: TestMode
}

// MARK: - Test Methodology

/// Documents the technical parameters used to derive test results,
/// essential for reproducibility and audit logs.
public struct TestMethodology: Codable {
    public let sampleCount: Int
    public let intervalMs: Int
    public let timeoutSeconds: Double
    public let method: String
    public let mode: String
}

// MARK: - Network Sample

/// Represents a single request-response cycle (a "packet" probe) within a test session.
public struct NetworkSample: Codable, Identifiable {
    public var id: UUID = UUID()
    public let index: Int
    public let startTime: Date
    public let endTime: Date?
    public let latencyMs: Double?
    public let success: Bool
    public let errorDescription: String?
}

// MARK: - Final Result

/// Encapsulates the aggregate results of a network audit.
public struct NetworkTestResult: Identifiable, Codable {
    
    public let id: UUID
    public let timestamp: Date

    public let config: NetworkTestConfig
    public let methodology: TestMethodology
    public let networkContext: NetworkContext

    public let avgLatencyMs: Double
    public let minLatencyMs: Double
    public let maxLatencyMs: Double
    public let jitterMs: Double
    public let packetLossPercent: Double

    public let stabilityScore: Int
    public let stabilityStatus: StabilityStatus

    public let totalSamples: Int
    public let failedSamples: Int

    /// The cryptographic hash representing the immutability of this result.
    public let dataHash: String

    /// Returns a new instance of the result with the cryptographic hash injected.
    public func withHash(_ hash: String) -> NetworkTestResult {
        return NetworkTestResult(
            id: self.id,
            timestamp: self.timestamp,
            config: self.config,
            methodology: self.methodology,
            networkContext: self.networkContext,
            avgLatencyMs: self.avgLatencyMs,
            minLatencyMs: self.minLatencyMs,
            maxLatencyMs: self.maxLatencyMs,
            jitterMs: self.jitterMs,
            packetLossPercent: self.packetLossPercent,
            stabilityScore: self.stabilityScore,
            stabilityStatus: self.stabilityStatus,
            totalSamples: self.totalSamples,
            failedSamples: self.failedSamples,
            dataHash: hash
        )
    }
}
