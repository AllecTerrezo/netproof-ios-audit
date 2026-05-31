import Foundation

/// Configuration utility for evidence verification URLs.
public enum VerificationConfig {
    // NOTE: Developers should point this to their own verification hosted page.
    // Ensure the verification service is publicly accessible for auditors.
    static let baseURL = URL(string: "https://opensource-netproof-example.com/verify/")!
    
    /// Constructs a verification URL with query parameters.
    /// - Parameters:
    ///   - hashHex: The SHA-256 hash to be verified.
    ///   - locale: Optional language identifier for the verification page.
    /// - Returns: A fully constructed verification URL.
    static func makeURL(hashHex: String, locale: String? = nil) -> URL {
        var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem(name: "h", value: hashHex)]
        if let locale, !locale.isEmpty {
            items.append(URLQueryItem(name: "lang", value: locale))
        }
        comps.queryItems = items
        return comps.url!
    }
}
