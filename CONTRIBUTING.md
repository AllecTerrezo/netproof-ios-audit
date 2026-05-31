# Contributing to NetProof

First off, thank you for considering contributing to NetProof! This project aims to provide cryptographically verifiable, privacy-first network diagnostics. 

To maintain a high standard of engineering, security, and privacy, we ask all contributors to follow the guidelines below.

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
* **No Massive Files:** Keep your types focused and small. If a service is doing too much, split it.

## Commit Message Convention

We follow the [Conventional Commits](https://www.conventionalcommits.org/) standard. This helps us keep a clean, readable history and automates changelog generation.

* `feat:` A new feature
* `fix:` A bug fix
* `docs:` Documentation only changes
* `style:` Changes that do not affect the meaning of the code (white-space, formatting, etc.)
* `refactor:` A code change that neither fixes a bug nor adds a feature
* `test:` Adding missing tests or correcting existing tests
* `chore:` Changes to the build process or auxiliary tools

**Example:** `feat: implement async URLSession diagnostic probe`

## Pull Request Process

* Ensure your code compiles without warnings on the latest stable version of Xcode.
* Fill out the Pull Request Template completely.
* Keep your PRs small and focused on a single issue or feature. If you have multiple unrelated changes, open multiple PRs.
* A maintainer will review your code. We may request changes to align with the project's architectural vision.
