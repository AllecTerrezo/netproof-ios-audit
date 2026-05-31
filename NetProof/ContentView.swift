import SwiftUI
import Combine

/// Main view of the NetProof application.
/// Displays network audit controls, privacy settings, and test results.
struct ContentView: View {

    @StateObject private var viewModel = TestRunnerViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                
                VStack(spacing: 24) {
                    
                    // MARK: - App Header
                    Text("app_title".localized)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("app_subtitle".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Text("app_value_proposition".localized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                    
                    Divider()
                    
                    // MARK: - Quick Test Section
                    VStack(spacing: 12) {
                        
                        Text("quick_test".localized)
                            .font(.headline)
                        
                        Text("quick_test_desc".localized)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button {
                            viewModel.runRealTest()
                        } label: {
                            if viewModel.isRunning {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("run_test".localized)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                    }
                    
                    // MARK: - Privacy / Analytics (Opt-in)
                    VStack(spacing: 6) {
                        Text("privacy_analytics_title".localized)
                            .font(.headline)
                        
                        Text("privacy_analytics_desc".localized)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Toggle("privacy_analytics_toggle".localized, isOn: Binding(
                            get: { AnalyticsEngine.shared.isOptedIn },
                            set: { AnalyticsEngine.shared.isOptedIn = $0 }
                        ))
                        .padding(.horizontal, 32)
                    }
                    .padding(.top, 12)
                    
                    // MARK: - Results Display
                    if let result = viewModel.lastResult {
                        
                        Divider()
                            .padding(.top, 16)
                        
                        VStack(spacing: 10) {
                            
                            Text("last_result_title".localized)
                                .font(.headline)
                            
                            let statusKey: String = {
                                switch result.stabilityStatus {
                                case .good: return "status_good"
                                case .unstable: return "status_unstable"
                                case .poor: return "status_poor"
                                }
                            }()
                            
                            VStack(spacing: 4) {
                                Text(
                                    String(
                                        format: "%@: %@ • %@: %d/100",
                                        "status_label".localized,
                                        statusKey.localized,
                                        "score_label".localized,
                                        Int(result.stabilityScore)
                                    )
                                )
                                .font(.subheadline)
                                
                                Text(actionableSummary(for: result))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                let host = result.config.targetURL.host ?? result.config.targetURL.absoluteString
                                let context = result.networkContext
                                
                                Text("\("target_host_label".localized): \(host)")
                                Text("\("connection_label".localized): \(context.connectionType.uiLocalizedKey.localized)")
                                
                                Text("\("avg_latency_label".localized): \(formatMs(result.avgLatencyMs))")
                                Text("\("min_latency_label".localized): \(formatMs(result.minLatencyMs))")
                                Text("\("max_latency_label".localized): \(formatMs(result.maxLatencyMs))")
                                Text("\("jitter_label".localized): \(formatMs(result.jitterMs))")
                                Text(
                                    "\("packet_loss_label".localized): " +
                                    String(format: "%.1f%%", result.packetLossPercent)
                                )
                                Text("\("total_samples_label".localized): \(result.totalSamples)")
                                Text("\("failed_samples_label".localized): \(result.failedSamples)")
                            }
                            .font(.footnote)
                            .padding(.top, 4)
                            
                            Text("result_evidence_explainer".localized)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                                .padding(.horizontal, 16)
                            
                            Text(nextStepRecommendation(for: result))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                                .padding(.horizontal, 16)
                            
                            Text("pdf_export_context".localized)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                            
                            // MARK: - Export Buttons
                            Button {
                                viewModel.exportPDF()
                            } label: {
                                Text("export_pdf_button".localized)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 32)
                            .padding(.top, 8)
                            .disabled(viewModel.isExportingPDF)
                            
                            Button {
                                if let data = UsageSummaryEngine.exportJSON() {
                                    do {
                                        let filename = "NetProof_UsageSummary_\(Int(Date().timeIntervalSince1970)).json"
                                        let url = try TempFileWriter.write(data: data, filename: filename)
                                        viewModel.exportedFileURL = url
                                        viewModel.exportedFileKind = .usageJSON
                                        viewModel.shouldShowShareSheet = true
                                    } catch {
                                        viewModel.lastExportErrorMessage = error.localizedDescription
                                    }
                                }
                            } label: {
                                Text("Export Usage Summary")
                                    .font(.footnote)
                            }
                            .padding(.top, 6)
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            Text("data_integrity_title".localized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(result.dataHash)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineLimit(4)
                                .padding(.horizontal, 16)
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("app_title".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $viewModel.shouldShowShareSheet) {
            if let url = viewModel.exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .onChange(of: viewModel.shouldShowShareSheet) { oldValue, newValue in
            guard newValue == true, oldValue == false else { return }
            AnalyticsEngine.shared.track(
                .shareSheetShown,
                connectionType: viewModel.lastResult?.networkContext.connectionType
            )
        }
        .alert("Export failed",
               isPresented: Binding(
                   get: { viewModel.lastExportErrorMessage != nil },
                   set: { if !$0 { viewModel.lastExportErrorMessage = nil } }
               ),
               actions: {
                   Button("OK", role: .cancel) { viewModel.lastExportErrorMessage = nil }
               },
               message: {
                   Text(viewModel.lastExportErrorMessage ?? "")
               }
        )
    }

    /// Formats values into milliseconds based on the current system locale.
    private func formatMs(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1

        let number = NSNumber(value: value)
        let formatted = formatter.string(from: number) ?? String(format: "%.1f", value)

        return "\(formatted) \("unit_ms".localized)"
    }
    
    /// Provides an actionable summary based on the stability status of the test result.
    private func actionableSummary(for result: NetworkTestResult) -> String {
        switch result.stabilityStatus {
        case .good: return "result_actionable_good".localized
        case .unstable: return "result_actionable_unstable".localized
        case .poor: return "result_actionable_poor".localized
        }
    }
    
    /// Suggests the next steps based on the connection quality.
    private func nextStepRecommendation(for result: NetworkTestResult) -> String {
        switch result.stabilityStatus {
        case .good: return "result_next_step_good".localized
        case .unstable: return "result_next_step_unstable".localized
        case .poor: return "result_next_step_poor".localized
        }
    }
}

#Preview {
    ContentView()
}
