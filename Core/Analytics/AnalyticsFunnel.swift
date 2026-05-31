import Foundation

/// Aggregates key user engagement metrics (the "funnel").
/// This structure tracks usage trends anonymously and offline.
struct AnalyticsFunnel: Codable {

    var testsStarted: Int = 0
    var testsCompleted: Int = 0
    var exportsTapped: Int = 0
    var exportsSucceeded: Int = 0
    var shareSheetShown: Int = 0

    /// Market signal data (aggregated by connection type, stored offline).
    var byConnection: [String: Int] = [:]

    /// Updates the funnel metrics based on an incoming analytics event.
    /// - Parameters:
    ///   - event: The name of the event triggered.
    ///   - connectionType: The network context (e.g., wifi, cellular) at the time of the event.
    mutating func apply(
        event: AnalyticsEventName,
        connectionType: NetworkConnectionType?
    ) {
        switch event {
        case .testStarted:
            testsStarted += 1
        case .testCompleted:
            testsCompleted += 1
        case .exportTapped:
            exportsTapped += 1
        case .exportSucceeded:
            exportsSucceeded += 1
        case .shareSheetShown:
            shareSheetShown += 1
        }

        // Aggregate connection statistics
        if let ct = connectionType {
            let key = ct.rawValue
            byConnection[key, default: 0] += 1
        }
    }
}
