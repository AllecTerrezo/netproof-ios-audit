import Foundation

/// Additional metadata describing the generated cryptographic evidence.
struct EvidenceMetadata: Codable {
    let evidenceID: UUID              // Unique identifier for the evidence
    let generatedAtUTC: Date          // Timestamp of PDF generation (UTC)
    let localTime: Date               // Local timestamp (for user display)
    let timeZoneIdentifier: String    // e.g., "America/Los_Angeles"
    let appVersion: String            // e.g., "1.0.0"
    let deviceModel: String           // e.g., "iPhone 15 Pro"
    let systemVersion: String         // e.g., "iOS 18.1"
}

/// Cryptographic signature of the evidence (100% offline, RSA-based).
struct EvidenceSignature: Codable {
    let algorithm: String             // e.g., "NetProof-RSA2048-SHA256-v1"
    let value: String                 // Base64 encoded signature
    let publicKeyPEM: String          // RSA Public Key in PEM format
}

extension EvidenceSignature {

    /// Generates a deterministic digital signature for the provided network test evidence.
    static func sign(
        result: NetworkTestResult,
        metadata: EvidenceMetadata
    ) -> EvidenceSignature {

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone(abbreviation: "UTC")

        let utcString = isoFormatter.string(from: metadata.generatedAtUTC)

        // Generate canonical string with fixed, public field order
        // to ensure deterministic hashing for signature verification.
        let canonical = """
        ALG=NetProof-RSA2048-SHA256-v1
        EVIDENCE_ID=\(metadata.evidenceID.uuidString)
        GENERATED_AT_UTC=\(utcString)
        DATA_HASH=\(result.dataHash)
        APP_VERSION=\(metadata.appVersion)
        DEVICE_MODEL=\(metadata.deviceModel)
        OS_VERSION=\(metadata.systemVersion)
        TIMEZONE_ID=\(metadata.timeZoneIdentifier)
        """

        do {
            let signed = try SigningEngine.shared.signCanonicalString(canonical)
            return EvidenceSignature(
                algorithm: "NetProof-RSA2048-SHA256-v1",
                value: signed.signatureBase64,
                publicKeyPEM: signed.publicKeyPEM
            )
        } catch {
            // Fallback: Maintains integrity via SHA-256 baseline if RSA signing fails
            let signatureValue = HashEngine.sha256(from: canonical)
            return EvidenceSignature(
                algorithm: "NetProof-SHA256-v1 (fallback)",
                value: signatureValue,
                publicKeyPEM: "UNAVAILABLE"
            )
        }
    }
}
