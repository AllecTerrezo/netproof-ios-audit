# NetProof

**NetProof** is a high-performance network auditing tool for iOS and macOS, designed for transparency and verifiable evidence collection.

### Core Philosophy
In a landscape of opaque network diagnostics, NetProof provides **cryptographically verifiable evidence**. Every network test result is locally signed and hashed, creating an immutable proof of connection quality suitable for professional audits, service-level agreement (SLA) verification, or dispute resolution with ISPs.

### Architecture
NetProof follows an **Offline-First** architecture. All computational processes, including cryptographic signing and PDF report generation, are performed entirely on-device, ensuring that sensitive diagnostic data never leaves your environment unless you explicitly choose to export it.

### Key Features
* **Verifiable Integrity:** Every test result produces a unique SHA-256 hash.
* **Hardware-Backed Security:** Cryptographic signatures are generated using RSA-2048 keys managed securely within the device Keychain.
* **Privacy-First:** Designed with compliance in mind (GDPR/LGPD). SSID and BSSID are masked to prevent individual tracking.
* **Actionable Reporting:** Generates professional, localized PDF evidence files with embedded QR codes for instant integrity validation.

### Privacy Compliance
NetProof adheres to strict privacy-by-design principles:
* **No PII Collection:** The application does not collect Personally Identifiable Information.
* **Masked Metadata:** Wi-Fi metadata is masked to ensure user anonymity.
* **Local Processing:** No external cloud API dependencies for core diagnostic functionality.

### Built With
* **Swift:** The core logic is built with modern, safe Swift 5.10+.
* **SwiftUI:** Declarative UI framework for a responsive and native experience.
* **Network Framework:** Low-level, high-performance path monitoring and diagnostic probes.
* **CryptoKit:** Apple's native framework for secure hashing and cryptographic operations.
* **Combine:** Used for reactive data flow and state management.

### Getting Started
1. Clone the repository to your local machine.
2. Open `NetProof.xcodeproj` in Xcode 15+.
3. Select your target device (Simulator or physical iOS/macOS device).
4. Build and run to start performing local network audits.

### Verification
To verify the integrity of a generated report:
1. Extract the data hash from the PDF or JSON export.
2. Use a SHA-256 tool to hash the raw test data.
3. Compare the generated hash with the one embedded in the evidence to ensure the report has not been tampered with.

---
*Licensed under the MIT License.*
