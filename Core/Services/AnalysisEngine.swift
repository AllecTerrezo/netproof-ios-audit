import Foundation

/// Engine responsible for calculating network performance metrics.
/// It applies robust statistical methods to derive stability scores, ensuring results
/// are defensible and resilient against isolated network jitter or spikes.
final class AnalysisEngine {

    /// Processes raw network samples to produce an integrity-validated `NetworkTestResult`.
    /// - Parameters:
    ///   - config: The configuration used for the test.
    ///   - samples: Raw per-packet data collected during the test.
    ///   - networkContext: The environmental context (Wi-Fi/Cellular) of the test.
    ///   - methodology: The technical parameters (sampling rate, timeout, etc.) used.
    /// - Returns: A `NetworkTestResult` containing calculated metrics and a cryptographic hash.
    func analyze(
        config: NetworkTestConfig,
        samples: [NetworkSample],
        networkContext: NetworkContext,
        methodology: TestMethodology
    ) -> NetworkTestResult {

        // Filter for valid latencies from successful requests
        let latencies = samples
            .filter { $0.success }
            .compactMap { $0.latencyMs }

        let totalSamples = samples.count
        let failedSamples = samples.filter { !$0.success }.count

        // Extract raw min/max from the success set
        let minLatencyMs = latencies.min() ?? 0.0
        let maxLatencyMs = latencies.max() ?? 0.0

        // Use a trimmed dataset for average and jitter calculations.
        // By removing the bottom/top 5%, we mitigate the impact of isolated spikes,
        // producing a result that is more representative of the actual connection quality.
        let statsLatencies = trimmed(latencies, fraction: 0.05)

        // Calculate Average Latency
        let avgLatencyMs: Double = {
            guard !statsLatencies.isEmpty else { return 0.0 }
            return statsLatencies.reduce(0, +) / Double(statsLatencies.count)
        }()

        // Calculate Jitter: Using sample standard deviation of Round-Trip Time (RTT)
        let jitterMs = sampleStdDev(statsLatencies)

        // Calculate Packet Loss percentage
        let packetLossPercent: Double = {
            guard totalSamples > 0 else { return 0.0 }
            return (Double(failedSamples) / Double(totalSamples)) * 100.0
        }()

        // Score Calculation: Aggregates penalties across metrics with specific caps
        // to prevent unbounded drops in score for minor fluctuations.
        let lossPenalty = min(40.0, packetLossPercent * 2.0)
        let jitterPenalty = min(30.0, jitterMs / 5.0)
        let latencyPenalty = min(30.0, avgLatencyMs / 20.0)

        var score = 100.0
        score -= lossPenalty
        score -= jitterPenalty
        score -= latencyPenalty
        let finalScore = max(0, min(100, score))
        let stabilityScore = Int(round(finalScore))

        // Stability classification: Maps scores to qualitative categories for UI/PDF output.
        let stabilityStatus: StabilityStatus
        switch stabilityScore {
        case 80...100:
            stabilityStatus = .good
        case 40..<80:
            stabilityStatus = .unstable
        default:
            stabilityStatus = .poor
        }

        // Initialize Result (Hash is computed in the next step to ensure integrity)
        var result = NetworkTestResult(
            id: UUID(),
            timestamp: Date(),
            config: config,
            methodology: methodology,
            networkContext: networkContext,
            avgLatencyMs: avgLatencyMs,
            minLatencyMs: minLatencyMs,
            maxLatencyMs: maxLatencyMs,
            jitterMs: jitterMs,
            packetLossPercent: packetLossPercent,
            stabilityScore: stabilityScore,
            stabilityStatus: stabilityStatus,
            totalSamples: totalSamples,
            failedSamples: failedSamples,
            dataHash: ""
        )

        // Inject the cryptographic hash for result immutability validation
        let hash = HashEngine.hash(from: result)
        result = result.withHash(hash)

        return result
    }

    // MARK: - Robust Statistics Helpers

    /// Trims a fraction of the data from the extremes (sorted array) to reduce outlier bias.
    /// - Parameters:
    ///   - values: The array of latencies.
    ///   - fraction: The fraction to trim (e.g., 0.05 trims 5% from top and bottom).
    private func trimmed(_ values: [Double], fraction: Double) -> [Double] {
        guard values.count >= 20 else { return values } // Skip trimming for small datasets
        let f = max(0.0, min(0.2, fraction)) // Safety cap: 20% max
        let sorted = values.sorted()
        let k = Int(Double(sorted.count) * f)
        if k == 0 { return sorted }
        return Array(sorted.dropFirst(k).dropLast(k))
    }

    /// Calculates the sample standard deviation (n-1).
    /// - Parameter values: The dataset to calculate.
    /// - Returns: The standard deviation, or 0.0 if n < 2.
    private func sampleStdDev(_ values: [Double]) -> Double {
        let n = values.count
        guard n >= 2 else { return 0.0 }
        let mean = values.reduce(0, +) / Double(n)
        let variance = values.reduce(0) { acc, x in
            let d = x - mean
            return acc + d * d
        } / Double(n - 1)
        return sqrt(variance)
    }
}
