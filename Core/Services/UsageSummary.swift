import Foundation

/// Data structure representing an aggregate snapshot of application usage.
struct UsageSummary: Codable {
    let generatedAt: Date
    let locale: String
    let appVersion: String

    let funnel: AnalyticsFunnel

    /// Calculates the average ratio of network tests completed per successful report export.
    var testsPerExport: Double {
        guard funnel.exportsSucceeded > 0 else { return 0 }
        return Double(funnel.testsCompleted) / Double(funnel.exportsSucceeded)
    }
}
