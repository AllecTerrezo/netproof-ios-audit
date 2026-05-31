import Network
import Foundation
import Dispatch

/// Engine responsible for capturing the current system network environment.
/// It provides a privacy-first snapshot of the connection state for audit records.
final class SystemContextEngine {

    /// Retrieves a minimal, privacy-compliant snapshot of the current network environment.
    /// - Returns: A `NetworkContext` structure representing the active connection state.
    func getCurrentContext() -> NetworkContext {
        let connectionType = detectConnectionType()

        // Privacy-First approach:
        // We deliberately do not collect BSSID/SSID by default on iOS to comply
        // with strict privacy regulations (GDPR/LGPD).
        // Fields are kept nil but preserved in the model for potential future opt-in extensions.
        let wifiSSIDMasked: String? = nil
        let wifiBSSIDMasked: String? = nil
        let wifiBand: String? = nil
        let wifiChannel: Int? = nil
        let wifiRSSI: Int? = nil

        return NetworkContext(
            connectionType: connectionType,
            wifiSSIDMasked: wifiSSIDMasked,
            wifiBSSIDMasked: wifiBSSIDMasked,
            wifiBand: wifiBand,
            wifiChannel: wifiChannel,
            wifiRSSI: wifiRSSI
        )
    }

    // MARK: - Helpers

    /// Detects the active network interface type using NWPathMonitor.
    /// - Returns: The detected `NetworkConnectionType`.
    private func detectConnectionType() -> NetworkConnectionType {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetProof.SystemContextEngine")
        let semaphore = DispatchSemaphore(value: 0)

        var detected: NetworkConnectionType = .other

        monitor.pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                detected = .wifi
            } else if path.usesInterfaceType(.cellular) {
                detected = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                detected = .wired
            } else {
                detected = .other
            }
            semaphore.signal()
        }

        monitor.start(queue: queue)
        // Wait up to 1 second for path discovery
        _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()

        return detected
    }
}
