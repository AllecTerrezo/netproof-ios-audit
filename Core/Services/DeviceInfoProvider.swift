import Foundation
import UIKit

/// Captures technical metadata regarding the hardware and operating system
/// of the device that executed the audit.
struct DeviceContext: Codable {
    let model: String
    let systemName: String
    let systemVersion: String
}

/// Captures technical metadata regarding the application instance
/// that generated the network evidence.
struct AppContext: Codable {
    let appName: String
    let bundleIdentifier: String
    let appVersion: String
    let buildNumber: String
}

/// Provider responsible for safely gathering device and application environment information.
enum DeviceInfoProvider {

    /// Captures the current device's hardware and OS state.
    /// - Returns: A `DeviceContext` instance containing system information.
    static func currentDevice() -> DeviceContext {
        let device = UIDevice.current
        return DeviceContext(
            model: device.model,
            systemName: device.systemName,
            systemVersion: device.systemVersion
        )
    }

    /// Captures the current application's build and metadata information.
    /// - Returns: An `AppContext` instance containing bundle and version details.
    static func currentApp() -> AppContext {
        let bundle = Bundle.main
        let info = bundle.infoDictionary ?? [:]

        let appName = info["CFBundleDisplayName"] as? String
            ?? info["CFBundleName"] as? String
            ?? "NetProof"

        let bundleID = bundle.bundleIdentifier ?? "unknown.bundle.id"
        let version = info["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info["CFBundleVersion"] as? String ?? "1"

        return AppContext(
            appName: appName,
            bundleIdentifier: bundleID,
            appVersion: version,
            buildNumber: build
        )
    }
}
