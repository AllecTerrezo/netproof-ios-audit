import Foundation

/// Computes high-level performance metrics based on a collection of raw analytics events.
struct AnalyticsMetrics: Codable {
    let testsStarted: Int
    let testsCompleted: Int
    let exportTapped: Int
    let exportSucceeded: Int

    // Engagement metrics
    let testsBeforeFirstExport: Int?
    let secondsToFirstExport: Double?

    /// Analyzes raw event data to generate business intelligence metrics.
    /// - Parameter events: An array of `AnalyticsEvent` to process.
    /// - Returns: A calculated `AnalyticsMetrics` instance.
    static func compute(from events: [AnalyticsEvent]) -> AnalyticsMetrics {
        // Sort events chronologically to ensure accurate time-based calculations
        let sorted = events.sorted { $0.ts < $1.ts }

        func count(_ name: AnalyticsEventName) -> Int {
            sorted.filter { $0.name == name }.count
        }

        let started = count(.testStarted)
        let completed = count(.testCompleted)
        let tapped = count(.exportTapped)
        let succeeded = count(.exportSucceeded)

        // Calculate engagement: tests completed before the user successfully performed their first export
        let firstExport = sorted.first { $0.name == .exportSucceeded }
        let testsBeforeFirst: Int? = {
            guard let firstExport else { return nil }
            return sorted.filter { $0.name == .testCompleted && $0.ts <= firstExport.ts }.count
        }()

        // Calculate time-to-first-conversion: time elapsed from the first test to the first export
        let firstTest = sorted.first { $0.name == .testStarted }
        let secsToFirstExport: Double? = {
            guard let firstExport, let firstTest else { return nil }
            return firstExport.ts.timeIntervalSince(firstTest.ts)
        }()

        return AnalyticsMetrics(
            testsStarted: started,
            testsCompleted: completed,
            exportTapped: tapped,
            exportSucceeded: succeeded,
            testsBeforeFirstExport: testsBeforeFirst,
            secondsToFirstExport: secsToFirstExport
        )
    }
}
