import Foundation
import Security

/// Engine responsible for performing local, hardware-backed cryptographic signatures.
/// It utilizes the iOS Keychain to manage RSA-2048 private keys, ensuring evidence integrity.
final class SigningEngine {

    static let shared = SigningEngine()
    private init() {}

    /// Unique tag used to identify the signing key within the iOS Keychain.
    private let keyTag: Data = "com.netproof.deviceSigningKey".data(using: .utf8)!

    /// Retrieves the existing private key from the Keychain or generates a new RSA-2048 keypair if missing.
    private func loadOrCreatePrivateKey() throws -> SecKey {
        // 1) Attempt to retrieve the existing key
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecReturnRef as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess {
            // Keychain returned a valid SecKey reference
            return item as! SecKey
        }

        // 2) Generate a new RSA 2048 keypair and store it securely in the Keychain
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: keyTag,
                // Restrict access for enhanced security
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error?.takeRetainedValue() as Error? ??
                  NSError(domain: "NetProof.SigningEngine", code: -1, userInfo: nil)
        }

        return privateKey
    }

    /// Extracts the public key component from a private key.
    private func publicKey(from privateKey: SecKey) throws -> SecKey {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw NSError(domain: "NetProof.SigningEngine", code: -2, userInfo: nil)
        }
        return publicKey
    }

    /// Exports the public key as a PEM-formatted string for inclusion in evidence reports.
    private func exportPublicKeyPEM(_ publicKey: SecKey) throws -> String {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            throw error?.takeRetainedValue() as Error? ??
                  NSError(domain: "NetProof.SigningEngine", code: -3, userInfo: nil)
        }

        let base64 = data.base64EncodedString(
            options: [.lineLength64Characters, .endLineWithLineFeed]
        )

        return """
        -----BEGIN PUBLIC KEY-----
        \(base64)
        -----END PUBLIC KEY-----
        """.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Signs a canonical string with RSA 2048 + SHA-256.
    func signCanonicalString(_ canonical: String) throws -> (signatureBase64: String, publicKeyPEM: String) {
        let messageData = Data(canonical.utf8)
        return try signData(messageData)
    }
    
    /// Signs arbitrary binary data with RSA 2048 + SHA-256 using PKCS#1 v1.5 padding.
    func signData(_ data: Data) throws -> (signatureBase64: String, publicKeyPEM: String) {
        let privateKey = try loadOrCreatePrivateKey()
        let publicKey = try publicKey(from: privateKey)

        let algorithm = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256
        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            throw NSError(domain: "NetProof.SigningEngine", code: -6, userInfo: nil)
        }

        var error: Unmanaged<CFError>?
        guard let signatureData = SecKeyCreateSignature(
            privateKey,
            algorithm,
            data as CFData,
            &error
        ) as Data? else {
            throw error?.takeRetainedValue() as Error? ??
                  NSError(domain: "NetProof.SigningEngine", code: -7, userInfo: nil)
        }

        let signatureBase64 = signatureData.base64EncodedString()
        let pem = try exportPublicKeyPEM(publicKey)

        return (signatureBase64, pem)
    }
}
