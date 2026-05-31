import Foundation

/// Defines the exhaustive list of trackable events within the application.
enum AnalyticsEventName: String, Codable {
    case testStarted
    case testCompleted
    case exportTapped
    case exportSucceeded
    case shareSheetShown
}

/// Represents a single, anonymized analytics event captured by the engine.
struct AnalyticsEvent: Codable {
    let id: UUID
    let ts: Date

    /// Anonymized persistent identifier generated locally on the device.
    /// Does not link to Apple ID or any PII (Personally Identifiable Information).
    let installationId: String

    /// The name of the captured event.
    let name: AnalyticsEventName

    /// Minimal network context allowed for aggregate analysis.
    let connectionType: NetworkConnectionType?

    /// Application version used for cohort analysis (market signaling), without identifying the user.
    let appVersion: String

    /// Optional: Numeric metadata associated with the event (e.g., duration in ms).
    let value: Double?

    /// Optional: Short, controlled descriptive string (e.g., "success", "error_code").
    let label: String?
}
