import Foundation
import SwiftUI
import Combine
import UIKit
import CryptoKit

@MainActor
final class TestRunnerViewModel: ObservableObject {

    @Published var isRunning: Bool = false
    @Published var lastResult: NetworkTestResult?
    @Published var lastSamples: [NetworkSample] = []

    // MARK: - ShareSheet State
    @Published var exportedFileURL: URL?
    @Published var exportedFileKind: ExportKind?

    enum ExportKind {
        case evidencePDF
        case usageJSON
    }

    @Published var shouldShowShareSheet: Bool = false

    // MARK: - UI States
    @Published var lastExportErrorMessage: String?

    // Anti double-tap protection
    @Published var isExportingPDF: Bool = false
    
    private let analysisEngine = AnalysisEngine()
    private let networkEngine = NetworkEngine()
    private let contextEngine = SystemContextEngine()


    // MARK: - PDF Export (Open-Source Core)
    func exportPDF() {
        // Anti double-tap (Source of truth)
        guard !isExportingPDF else { return }
        isExportingPDF = true
        defer { isExportingPDF = false }

        // 1) Ensure a result has been calculated
        guard let result = lastResult else { return }

        AnalyticsEngine.shared.track(.exportTapped, connectionType: result.networkContext.connectionType)

        let now = Date()
        let evidenceID = UUID()
        let timeZoneID = TimeZone.current.identifier

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let systemVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model

        let metadata = EvidenceMetadata(
            evidenceID: evidenceID,
            generatedAtUTC: now,
            localTime: now,
            timeZoneIdentifier: timeZoneID,
            appVersion: appVersion,
            deviceModel: deviceModel,
            systemVersion: systemVersion
        )

        // 2) Generate partial PDF (WITHOUT signature)
        let partialPDF = PDFEvidenceEngine.generate(
            result: result,
            samples: lastSamples,
            metadata: metadata,
            signature: nil
        )

        // (Optional Debug) Log the payload hash
        let hash = SHA256.hash(data: partialPDF)
        print("PDF body SHA-256 (hex): \(hash.compactMap { String(format: "%02x", $0) }.joined())")

        // 3) Sign locally (USING SigningEngine as the cryptographic source of truth)
        do {
            let signed = try SigningEngine.shared.signData(partialPDF)
            let signatureValue = signed.signatureBase64
            let publicPEM = signed.publicKeyPEM

            let signature = EvidenceSignature(
                algorithm: "RSA-2048 / SHA-256",
                value: signatureValue,
                publicKeyPEM: publicPEM
            )

            // 4) Generate final PDF (WITH embedded signature)
            let finalPDF = PDFEvidenceEngine.generate(
                result: result,
                samples: lastSamples,
                metadata: metadata,
                signature: signature
            )

            // 5) Deliver to ShareSheet
            let filename = "NetProof_Evidence_\(evidenceID.uuidString.prefix(8)).pdf"
            do {
                let url = try TempFileWriter.writePDF(data: finalPDF, filename: filename)
                self.exportedFileURL = url
                self.exportedFileKind = .evidencePDF
                self.shouldShowShareSheet = true
                
                AnalyticsEngine.shared.track(.exportSucceeded, connectionType: result.networkContext.connectionType)
            }
        } catch {
            print("Signing failed: \(error)")
            self.lastExportErrorMessage = error.localizedDescription
        }
    }


    // MARK: - FAKE Test (Debug)

    func runFakeTest() {
        isRunning = true
        lastResult = nil
        lastSamples = []

        let config = NetworkTestConfig(
            targetURL: URL(string: "https://www.apple.com")!,
            sampleCount: 15,
            intervalMs: 200,
            timeoutSeconds: 5,
            mode: .single
        )

        var samples: [NetworkSample] = []
        let now = Date()

        for i in 0..<config.sampleCount {
            let startTime = now.addingTimeInterval(Double(i) * 0.5)
            let success = Bool.random()

            if success {
                let latency = Double.random(in: 30...300)
                let endTime = startTime.addingTimeInterval(latency / 1000.0)
                samples.append(NetworkSample(
                    index: i,
                    startTime: startTime,
                    endTime: endTime,
                    latencyMs: latency,
                    success: true,
                    errorDescription: nil
                ))
            } else {
                let endTime = startTime.addingTimeInterval(5.0)
                samples.append(NetworkSample(
                    index: i,
                    startTime: startTime,
                    endTime: endTime,
                    latencyMs: nil,
                    success: false,
                    errorDescription: "Fake timeout"
                ))
            }
        }

        lastSamples = samples

        let fakeContext = NetworkContext(
            connectionType: .wifi,
            wifiSSIDMasked: nil,
            wifiBSSIDMasked: nil,
            wifiBand: nil,
            wifiChannel: nil,
            wifiRSSI: nil
        )

        let methodology = TestMethodology(
            sampleCount: config.sampleCount,
            intervalMs: config.intervalMs,
            timeoutSeconds: config.timeoutSeconds,
            method: "FAKE",
            mode: "debug"
        )

        lastResult = analysisEngine.analyze(
            config: config,
            samples: samples,
            networkContext: fakeContext,
            methodology: methodology
        )

        isRunning = false
    }

    // MARK: - REAL Test

    func runRealTest() {
        isRunning = true
        lastResult = nil
        lastSamples = []

        let config = NetworkTestConfig(
            targetURL: URL(string: "https://www.apple.com")!,
            sampleCount: 20,
            intervalMs: 200,
            timeoutSeconds: 2,
            mode: .single
        )

        let networkContext = contextEngine.getCurrentContext()

        // 📌 TRACKING
        AnalyticsEngine.shared.track(.testStarted, connectionType: networkContext.connectionType)
        
        let methodology = TestMethodology(
            sampleCount: config.sampleCount,
            intervalMs: config.intervalMs,
            timeoutSeconds: config.timeoutSeconds,
            method: "HTTP HEAD + GET fallback",
            mode: "foreground"
        )

        Task {
            let t0 = Date()
            let samples = await networkEngine.runTest(config: config) { _ in }
            self.lastSamples = samples

            let result = self.analysisEngine.analyze(
                config: config,
                samples: samples,
                networkContext: networkContext,
                methodology: methodology
            )

            self.lastResult = result
            self.isRunning = false
            
            AnalyticsEngine.shared.track(
                .testCompleted,
                connectionType: networkContext.connectionType,
                value: Date().timeIntervalSince(t0),
                label: "duration_seconds"
            )
        }
    }
}
