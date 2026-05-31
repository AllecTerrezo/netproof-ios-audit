import Foundation

/// Central engine for handling local, privacy-first analytics events.
/// This engine aggregates usage metrics into a funnel, stored locally on the device.
final class AnalyticsEngine {

    static let shared = AnalyticsEngine()
    private init() {}

    /// Privacy-first toggle: analytics are only tracked if opted-in by the user.
    var isOptedIn: Bool {
        get { UserDefaults.standard.bool(forKey: "analytics_opt_in") }
        set { UserDefaults.standard.set(newValue, forKey: "analytics_opt_in") }
    }

    /// Anonymous identifier managed internally, ensuring persistence without external dependency.
    private var installationID: String {
        let key = "analytics_installation_id"
        if let existingId = UserDefaults.standard.string(forKey: key) {
            return existingId
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    private var funnel: AnalyticsFunnel = AnalyticsFunnelStore.shared.load()

    /// Tracks an analytics event if the user has opted in.
    /// - Parameters:
    ///   - name: The specific event identifier (e.g., testStarted).
    ///   - connectionType: The network context (e.g., wifi, cellular).
    ///   - value: Optional numeric metadata for the event.
    ///   - label: Optional short descriptive string.
    func track(
        _ name: AnalyticsEventName,
        connectionType: NetworkConnectionType? = nil,
        value: Double? = nil,
        label: String? = nil
    ) {
        guard isOptedIn else { return }

        let appVersion =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "Unknown"

        let ev = AnalyticsEvent(
            id: UUID(),
            ts: Date(),
            installationId: self.installationID,
            name: name,
            connectionType: connectionType,
            appVersion: appVersion,
            value: value,
            label: label
        )

        AnalyticsStore.shared.append(ev)
        updateFunnel(for: name, connectionType: connectionType)
    }

    /// Updates the aggregated funnel state and persists it to disk.
    private func updateFunnel(
        for event: AnalyticsEventName,
        connectionType: NetworkConnectionType?
    ) {
        funnel.apply(event: event, connectionType: connectionType)
        AnalyticsFunnelStore.shared.save(funnel)
    }

    /// Returns the currently aggregated usage summary.
    func exportUsageSummary() -> AnalyticsFunnel {
        funnel
    }
}
