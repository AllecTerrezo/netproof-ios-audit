import Network
import Foundation
import Dispatch

/// Engine responsible for executing the network audit tests.
/// This engine performs diagnostic probes against a target host and collects latency and success metrics.
final class NetworkEngine {

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = false
        // Default request timeout; can be overridden by specific test configurations
        config.timeoutIntervalForRequest = 5
        self.session = URLSession(configuration: config)
    }

    /// Executes a real-time network diagnostic test.
    ///
    /// The engine employs a resilient strategy: it attempts a lightweight "HEAD" request first to minimize
    /// bandwidth consumption, falling back to a "GET" request if the server restricts HEAD requests.
    ///
    /// - Parameters:
    ///   - config: Test parameters (target URL, sample count, interval, timeout).
    ///   - onSample: Callback invoked immediately after each collected sample for UI updates.
    /// - Returns: A collection of `NetworkSample` containing success states, latency, and error details.
    func runTest(
        config: NetworkTestConfig,
        onSample: @escaping (NetworkSample) -> Void
    ) async -> [NetworkSample] {

        var samples: [NetworkSample] = []

        for i in 0..<config.sampleCount {
            if Task.isCancelled { break }

            let startTime = Date()

            var sample = NetworkSample(
                index: i,
                startTime: startTime,
                endTime: nil,
                latencyMs: nil,
                success: false,
                errorDescription: nil
            )

            do {
                // Primary attempt: HEAD request (optimized for low bandwidth)
                var request = URLRequest(url: config.targetURL)
                request.httpMethod = "HEAD"
                request.timeoutInterval = config.timeoutSeconds

                do {
                    _ = try await session.data(for: request)
                } catch {
                    // Fallback: GET request (in case the target server blocks HEAD methods)
                    var fallbackRequest = URLRequest(url: config.targetURL)
                    fallbackRequest.httpMethod = "GET"
                    fallbackRequest.timeoutInterval = config.timeoutSeconds

                    _ = try await session.data(for: fallbackRequest)
                }

                let endTime = Date()
                let latencyMs = endTime.timeIntervalSince(startTime) * 1000.0

                sample = NetworkSample(
                    index: i,
                    startTime: startTime,
                    endTime: endTime,
                    latencyMs: latencyMs,
                    success: true,
                    errorDescription: nil
                )

            } catch {
                let endTime = Date()
                sample = NetworkSample(
                    index: i,
                    startTime: startTime,
                    endTime: endTime,
                    latencyMs: nil,
                    success: false,
                    errorDescription: error.localizedDescription
                )
            }

            samples.append(sample)

            // Notify caller about the new sample (MainActor required for UI-bound operations)
            await MainActor.run {
                onSample(sample)
            }

            // Enforce specified interval before firing the subsequent sample
            if i < config.sampleCount - 1 {
                let intervalNs = UInt64(config.intervalMs) * 1_000_000
                try? await Task.sleep(nanoseconds: intervalNs)
            }
        }

        return samples
    }
}
