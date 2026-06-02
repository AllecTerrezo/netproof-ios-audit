# Contributing to NetProof

First off, thank you for considering contributing to NetProof! This project aims to provide cryptographically verifiable, privacy-first network diagnostics. 

As the project scales, the core maintainership is focused strictly on **architectural curation, code review, and project direction**. This means the community is highly encouraged to take ownership of coding features, refactoring, and building infrastructure.

To maintain a high standard of engineering, security, and privacy, we ask all contributors to follow the guidelines below.

## Where We Need Help (Project Roadmap)

Whether you are a junior developer looking for a quick win or a Staff Engineer looking for a complex architectural challenge, there is a place for you here.

### 🔴 High Priority & Complex (Infrastructure & Testing)
* **Core Engine Modularization (SPM):** Our strategic goal is to decouple the core network auditing and cryptographic signing logic from the main iOS application. We need to extract the `AnalysisEngine` and the cryptographic components of `PDFEvidenceEngine` into a standalone, dependency-free Swift Package (SPM). This will allow other engineers to seamlessly integrate our tamper-evident diagnostics into their own enterprise stacks.
* **XCTest Framework Setup:** We need to establish a robust unit testing environment. This involves setting up the `XCTest` target, marking the scheme as "Shared," and pushing it to the repository so our CI/CD pipeline can run actual tests.
* **Core Logic Unit Tests:** Implement comprehensive unit tests for `AnalysisEngine` (verifying trimmed means and jitter calculations) and `PDFEvidenceEngine` (verifying local RSA-2048 signing and SHA-256 hashing).
* **Dependency Injection:** Refactor ViewModels (like `TestRunnerViewModel`) to accept dependencies via protocols, enabling proper mocking and testing.

### 🟡 Intermediate (Refactoring & Architecture)
* **De-massive Files:** `PDFEvidenceEngine.swift` is currently handling too many responsibilities (layout, drawing, and cryptography). We need to split this into smaller, focused services (e.g., separating the crypto engine from the PDF canvas drawer).
* **Network Layer Polish:** Transition the current `URLSession` implementation to utilize Apple's lower-level `Network` framework (`NWConnection`) for more granular, high-performance path monitoring.

### 🟢 Accessible & Quick Wins
* UI/UX improvements in SwiftUI.
* Improving Markdown documentation and inline SwiftDoc comments.
* Adding new localizations for the PDF report outputs.

## Branching Strategy

We keep it simple and effective using a **Trunk-Based Development** approach.
* **`main`** is our source of truth. It must always be stable and deployable.
* All new development, bug fixes, or documentation updates should be done in feature branches branching off from `main`.

## How to Contribute

1. **Fork the repository** and clone it locally.
2. **Create a branch** for your feature or bugfix:
   `git checkout -b feature/your-feature-name` or `git checkout -b fix/your-bugfix-name`
3. **Commit your changes** following our commit guidelines (see below).
4. **Push to your fork** and open a Pull Request (PR) against the `main` branch.

## Engineering Standards & Privacy

NetProof is built on a foundation of trust and verifiable data. When writing code, please ensure:
* **Offline-First:** Core functionalities must not rely on external APIs. All cryptographic hashing and PDF generation must happen on-device.
* **Privacy by Design:** Never log, store, or transmit Personally Identifiable Information (PII). Respect metadata masking (e.g., SSID/BSSID hiding).
* **Modern Swift:** Utilize Swift concurrency (`async/await`, `@MainActor`) over legacy callback patterns where appropriate. Keep the MVVM architecture clean.
* **Testability:** Any new core logic or statistical service must be accompanied by unit tests. 

## Commit Message Convention

We follow the [Conventional Commits](https://www.conventionalcommits.org/) standard. This helps us keep a clean, readable history and automates changelog generation.

* `feat:` A new feature
* `fix:` A bug fix
* `docs:` Documentation only changes
* `style:` Changes that do not affect the meaning of the code (white-space, formatting, etc.)
* `refactor:` A code change that neither fixes a bug nor adds a feature
* `test:` Adding missing tests or correcting existing tests
* `chore:` Changes to the build process or auxiliary tools

**Example:** `feat: implement async NWConnection diagnostic probe`

## Pull Request Process & Curation

* Ensure your code compiles without warnings on the latest stable version of Xcode.
* Fill out the Pull Request Template completely.
* Keep your PRs small and focused on a single issue or feature. If you have multiple unrelated changes, open multiple PRs.
* **Strict Curation:** A maintainer will rigorously review your code. We prioritize security, privacy, and architectural cleanliness over shipping fast. Be prepared to receive constructive feedback and make adjustments to align with the project's vision.
