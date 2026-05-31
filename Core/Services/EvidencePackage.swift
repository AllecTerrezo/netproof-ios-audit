import Foundation
import UIKit

/// Represents a complete evidence package for a network audit session.
/// This structure acts as the primary data model for both PDF report generation and JSON archival.
struct EvidencePackage: Codable, Identifiable {
    
    // Unique identifier for the evidence (must match the underlying test result ID)
    let id: UUID

    // Timestamp of evidence creation
    let createdAt: Date

    // Localization context for accurate reporting
    let localeIdentifier: String      // e.g., "en_US", "pt_BR"
    let timeZoneIdentifier: String    // e.g., "America/Los_Angeles"

    // Device technical information
    let deviceModel: String           // e.g., "iPhone"
    let systemName: String            // e.g., "iOS"
    let systemVersion: String         // e.g., "18.0"

    // Application build information
    let appVersion: String            // e.g., "1.0"
    let appBuild: String              // e.g., "5"

    // The core technical test result data
    let testResult: NetworkTestResult

    // MARK: - Derived Properties

    /// Date formatted in ISO 8601 (UTC) - used as the strong technical standard for auditability.
    var createdAtISO8601: String {
        DateFormattingEngine.isoString(from: createdAt)
    }

    /// Human-readable date format, localized based on the user's specific locale and timezone settings.
    var createdAtLocalized: String {
        let locale = Locale(identifier: localeIdentifier)
        let timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        return DateFormattingEngine.localizedDateTime(
            from: createdAt,
            locale: locale,
            timeZone: timeZone
        )
    }
}

// MARK: - Factory Methods

extension EvidencePackage {

    /// Constructs an `EvidencePackage` from a generated `NetworkTestResult`.
    /// Typically invoked immediately following the completion of a network audit.
    /// - Parameter result: The audit result to encapsulate.
    /// - Returns: A fully populated `EvidencePackage` instance.
    static func from(result: NetworkTestResult) -> EvidencePackage {
        let now = result.timestamp

        let locale = Locale.current
        let timeZone = TimeZone.current

        let device = UIDevice.current
        let bundle = Bundle.main

        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        return EvidencePackage(
            id: result.id,
            createdAt: now,
            localeIdentifier: locale.identifier,
            timeZoneIdentifier: timeZone.identifier,
            deviceModel: device.model,
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            appVersion: version,
            appBuild: build,
            testResult: result
        )
    }
}
