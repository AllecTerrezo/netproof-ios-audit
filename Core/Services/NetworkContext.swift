import Foundation

// MARK: - 1. Connection Types

/// Supported network connection categories.
///
/// Compatibility Note:
/// - Uses standard lowercase raw values (e.g., 'wifi', 'cellular') for serialization.
/// - The custom decoder provides a fallback mechanism for legacy capitalized strings
///   ("Wi-Fi", "Cellular") to maintain backward compatibility with older test logs.
public enum NetworkConnectionType: String, Codable {
    case wifi
    case cellular
    case wired
    case other
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)

        // Try standard lowercase format
        if let v = NetworkConnectionType(rawValue: raw.lowercased()) {
            self = v
            return
        }

        // Fallback for legacy format
        switch raw {
        case "Wi-Fi":    self = .wifi
        case "Cellular": self = .cellular
        case "Wired":    self = .wired
        case "Other":    self = .other
        case "Unknown":  self = .unknown
        default:         self = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    // MARK: - Localizable Keys

    /// Key used for App UI localization.
    public var uiLocalizedKey: String {
        switch self {
        case .wifi: return "connection_wifi"
        case .cellular: return "connection_cellular"
        case .wired: return "connection_wired"
        case .other: return "connection_other"
        case .unknown: return "connection_unknown"
        }
    }

    /// Key used for PDF report localization.
    public var pdfLocalizedKey: String {
        switch self {
        case .wifi: return "pdf_connection_wifi"
        case .cellular: return "pdf_connection_cellular"
        case .wired: return "pdf_connection_wired"
        case .other: return "pdf_connection_other"
        case .unknown: return "pdf_connection_unknown"
        }
    }
}

// MARK: - 2. Network Context

/// Captures a snapshot of the network environment during the audit session.
///
/// Privacy-First Architecture:
/// This structure adheres to GDPR/LGPD compliance principles. It is strictly minimalist.
/// SSID and BSSID are masked, and specific fields may be nil depending on
/// iOS location permission availability and restricted public APIs.
public struct NetworkContext: Codable {

    /// The active network interface type during the audit.
    public let connectionType: NetworkConnectionType

    // MARK: - Wi-Fi Metadata (Optional)
    
    /// Masked SSID to prevent individual user tracking.
    public let wifiSSIDMasked: String?
    
    /// Masked BSSID to comply with privacy regulations.
    public let wifiBSSIDMasked: String?
    
    public let wifiBand: String?
    public let wifiChannel: Int?
    public let wifiRSSI: Int?
}
