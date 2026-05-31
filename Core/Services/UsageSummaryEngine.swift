import Foundation

/// Engine responsible for generating and exporting application usage summaries.
final class UsageSummaryEngine {

    /// Generates a `UsageSummary` instance based on the currently stored analytics funnel.
    static func generate() -> UsageSummary {
        let funnel = AnalyticsFunnelStore.shared.load()

        return UsageSummary(
            generatedAt: Date(),
            locale: Locale.current.identifier,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            funnel: funnel
        )
    }

    /// Encodes and exports the current usage summary into JSON data.
    /// - Returns: The JSON-encoded summary data, or nil if encoding fails.
    static func exportJSON() -> Data? {
        let summary = generate()
        return try? JSONEncoder().encode(summary)
    }
}
