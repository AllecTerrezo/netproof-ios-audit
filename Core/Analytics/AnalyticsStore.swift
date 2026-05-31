import Foundation

/// Handles persistent local storage for analytics events.
/// Uses a JSON Lines (.jsonl) format to allow efficient appending and rotation.
final class AnalyticsStore {
    static let shared = AnalyticsStore()
    private init() {}

    private let fileName = "analytics_events.jsonl"
    private let maxBytes: Int = 300_000 // ~300KB storage limit
    private let retentionDays: Int = 30

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }

    /// Appends a new analytics event to the local storage and triggers retention enforcement.
    /// - Parameter event: The `AnalyticsEvent` to store.
    func append(_ event: AnalyticsEvent) {
        do {
            let data = try JSONEncoder().encode(event)
            guard var line = String(data: data, encoding: .utf8) else { return }
            line.append("\n")

            if !FileManager.default.fileExists(atPath: fileURL.path) {
                FileManager.default.createFile(atPath: fileURL.path, contents: nil)
            }

            let handle = try FileHandle(forWritingTo: fileURL)
            try handle.seekToEnd()
            if let lineData = line.data(using: .utf8) {
                try handle.write(contentsOf: lineData)
            }
            try handle.close()

            enforceRetention()
        } catch {
            // Best-effort storage: logging failures should not interrupt the app flow
        }
    }

    /// Reads all stored analytics events from the file.
    /// - Returns: An array of decoded `AnalyticsEvent` objects.
    func readAll() -> [AnalyticsEvent] {
        guard let data = try? Data(contentsOf: fileURL),
              let text = String(data: data, encoding: .utf8) else { return [] }

        var events: [AnalyticsEvent] = []
        let decoder = JSONDecoder()

        for line in text.split(separator: "\n") {
            if let lineData = line.data(using: .utf8),
               let ev = try? decoder.decode(AnalyticsEvent.self, from: lineData) {
                events.append(ev)
            }
        }
        return events
    }

    /// Deletes the analytics file.
    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Enforces storage retention policy (30 days) and file size limits (300KB).
    private func enforceRetention() {
        // 1) Filter events by retention date
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date.distantPast
        let events = readAll().filter { $0.ts >= cutoff }

        // 2) Check if file size exceeds limit or if optimization is needed
        let currentSize = ((try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size]) as? Int) ?? 0
        if currentSize <= maxBytes && events.count > 0 { return }

        // 3) Rewrite compact log
        let encoder = JSONEncoder()
        var out = ""
        // Hard cap at 2000 events to maintain performance
        for ev in events.suffix(2000) {
            if let d = try? encoder.encode(ev),
               let s = String(data: d, encoding: .utf8) {
                out += s + "\n"
            }
        }
        try? out.data(using: .utf8)?.write(to: fileURL, options: .atomic)
    }
}
