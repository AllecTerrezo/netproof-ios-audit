import Foundation

/// Persists the aggregated analytics funnel data locally using UserDefaults.
/// This lightweight storage is sufficient since the funnel only holds anonymous, aggregated integer counts.
final class AnalyticsFunnelStore {

    static let shared = AnalyticsFunnelStore()
    private init() {}

    private let key = "analytics_funnel_v1"

    /// Loads the saved funnel state from local storage.
    /// - Returns: The stored `AnalyticsFunnel`, or a fresh, empty instance if none exists or decoding fails.
    func load() -> AnalyticsFunnel {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let obj = try? JSONDecoder().decode(AnalyticsFunnel.self, from: data)
        else {
            return AnalyticsFunnel()
        }
        return obj
    }

    /// Serializes and saves the current funnel state to local storage.
    /// - Parameter funnel: The updated `AnalyticsFunnel` to persist.
    func save(_ funnel: AnalyticsFunnel) {
        guard let data = try? JSONEncoder().encode(funnel) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    /// Clears the saved funnel state from local storage.
    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
