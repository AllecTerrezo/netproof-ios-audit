import Foundation

/// Centralizes all date formatting logic for NetProof.
/// Ensures consistent data handling:
/// - ISO 8601: The technical standard for audit logs (strictly UTC).
/// - Localized: Human-readable formats respecting the user's language and region.
enum DateFormattingEngine {

    /// Formatter for ISO 8601 with fractional seconds (e.g., 2025-11-25T16:30:12.345Z).
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Strictly UTC for cryptographic consistency
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        return formatter
    }()

    /// Formatter for user-facing UI and Evidence PDF reports.
    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Returns an ISO 8601 formatted string in UTC.
    /// Used as the robust technical standard for reports and audit logs.
    /// - Parameter date: The date to format.
    /// - Returns: An ISO 8601 compliant string.
    static func isoString(from date: Date) -> String {
        return isoFormatter.string(from: date)
    }

    /// Returns a user-friendly localized string.
    /// Respects the user's specific language, region, and timezone settings.
    /// - Parameters:
    ///   - date: The date to format.
    ///   - locale: The user's locale (defaults to `.current`).
    ///   - timeZone: The user's timezone (defaults to `.current`).
    /// - Returns: A localized date and time string.
    static func localizedDateTime(
        from date: Date,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        displayFormatter.locale = locale
        displayFormatter.timeZone = timeZone
        return displayFormatter.string(from: date)
    }
}
