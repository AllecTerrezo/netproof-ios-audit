import Foundation
import UIKit
import PDFKit
import CoreImage.CIFilterBuiltins

final class PDFEvidenceEngine {
    static func generate(
        result: NetworkTestResult,
        samples: [NetworkSample],
        metadata: EvidenceMetadata,
        signature: EvidenceSignature?
    ) -> Data {

        // Page dimensions (approximate A4 in points)
        let pageWidth: CGFloat = 595.0
        let pageHeight: CGFloat = 842.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let padding: CGFloat = 32.0
        
        // Localization helper (using main bundle)
        @inline(__always)
        func L(_ key: String) -> String {
            NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
        }
        
        // Set PDF document metadata
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: L("pdf_document_title"),
            kCGPDFContextAuthor as String: "NetProof",
            kCGPDFContextCreator as String: "NetProof iOS/macOS",
            kCGPDFContextSubject as String: L("pdf_document_subject")
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        
        // Use the verification config to generate the report URL
        let verificationURL = VerificationConfig.makeURL(hashHex: result.dataHash)
        let verificationURLString = verificationURL.absoluteString

        // Capture rectangles for Page 2 annotations
        var qrRectOnPage2: CGRect?
        var linkTextRectOnPage2: CGRect?

        let data = renderer.pdfData { context in
            context.beginPage()

            // Optional discrete watermark (localized)
            drawWatermark(L("pdf_watermark"))
        
            @discardableResult
            // Draws a QR code for the provided string.
            func drawQRCode(_ string: String, size: CGFloat) -> CGRect? {
                let filter = CIFilter.qrCodeGenerator()
                filter.setValue(Data(string.utf8), forKey: "inputMessage")

                guard let outputImage = filter.outputImage else {
                    y += 12
                    return nil
                }

                let scale = size / max(outputImage.extent.width, outputImage.extent.height)
                let output = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

                let contextCI = CIContext(options: nil)
                guard let cgImage = contextCI.createCGImage(output, from: output.extent) else {
                    y += 12
                    return nil
                }

                let rect = CGRect(
                    x: (pageRect.width - size) / 2,
                    y: y,
                    width: size,
                    height: size
                )

                UIImage(cgImage: cgImage).draw(in: rect)

                y += size + 16
                return rect
            }
        
            var y: CGFloat = padding

            // MARK: - Helpers

            func drawLine(spacingBefore: CGFloat = 8, spacingAfter: CGFloat = 8) {
                y += spacingBefore
                let path = UIBezierPath()
                path.move(to: CGPoint(x: padding, y: y))
                path.addLine(to: CGPoint(x: pageRect.width - padding, y: y))
                path.lineWidth = 0.5
                UIColor.lightGray.setStroke()
                path.stroke()
                y += spacingAfter
            }

            func drawText(
                _ text: String,
                font: UIFont,
                color: UIColor = .black,
                alignment: NSTextAlignment = .left,
                lineSpacing: CGFloat = 2.0
            ) {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping
                paragraphStyle.alignment = alignment
                paragraphStyle.lineSpacing = lineSpacing

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraphStyle
                ]

                let attributed = NSAttributedString(string: text, attributes: attributes)

                let size = attributed.boundingRect(
                    with: CGSize(
                        width: pageRect.width - 2 * padding,
                        height: .greatestFiniteMagnitude
                    ),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                )

                attributed.draw(
                    in: CGRect(
                        x: padding,
                        y: y,
                        width: pageRect.width - 2 * padding,
                        height: size.height
                    )
                )

                y += size.height + 4
            }
            
            /// Draws text in a fixed rectangle without affecting the cursor Y.
            func drawTextInRect(
                _ text: String,
                rect: CGRect,
                font: UIFont,
                color: UIColor = .black,
                alignment: NSTextAlignment = .left,
                lineSpacing: CGFloat = 2.0
            ) {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping
                paragraphStyle.alignment = alignment
                paragraphStyle.lineSpacing = lineSpacing

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraphStyle
                ]

                let attributed = NSAttributedString(string: text, attributes: attributes)
                attributed.draw(in: rect)
            }
            
            /// Draws a filled rectangle (used for branding/institutional headers).
            func drawFilledRect(
                x: CGFloat,
                y: CGFloat,
                width: CGFloat,
                height: CGFloat,
                color: UIColor
            ) {
                guard width > 0, height > 0 else { return }

                let rect = CGRect(x: x, y: y, width: width, height: height)

                // Renders a soft watermark at a diagonal angle.
                guard pageRect.intersects(rect) else { return }

                guard let ctx = UIGraphicsGetCurrentContext() else { return }

                ctx.saveGState()
                defer { ctx.restoreGState() }

                ctx.setFillColor(color.cgColor)
                ctx.fill(rect)
            }

            func drawWatermark(_ text: String) {
                guard !text.isEmpty else { return }

                let baseFont = UIFont.systemFont(ofSize: 48, weight: .semibold)
                let color = UIColor(white: 0.85, alpha: 0.18)

                let inset: CGFloat = 40
                let maxW = pageRect.width - inset * 2
                let _ = pageRect.height - inset * 2

                var fontSize: CGFloat = baseFont.pointSize
                var font = baseFont.withSize(fontSize)

                func measure(_ f: UIFont) -> CGSize {
                    let attrs: [NSAttributedString.Key: Any] = [.font: f]
                    return (text as NSString).size(withAttributes: attrs)
                }

                var sz = measure(font)
                while (sz.width > maxW || sz.height > 80) && fontSize > 18 {
                    fontSize -= 2
                    font = baseFont.withSize(fontSize)
                    sz = measure(font)
                }

                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]

                let center = CGPoint(x: pageRect.midX, y: pageRect.midY)

                UIGraphicsGetCurrentContext()?.saveGState()
                defer { UIGraphicsGetCurrentContext()?.restoreGState() }

                UIGraphicsGetCurrentContext()?.translateBy(x: center.x, y: center.y)
                UIGraphicsGetCurrentContext()?.rotate(by: -CGFloat.pi / 6) // ~ -30°

                (text as NSString).draw(
                    at: CGPoint(x: -sz.width / 2, y: -sz.height / 2),
                    withAttributes: attrs
                )
            }

            /// Draws a "Key : Value" row with aligned columns.
            func drawKeyValueRow(
                key: String,
                value: String,
                font: UIFont
            ) {
                let paragraphLeft = NSMutableParagraphStyle()
                paragraphLeft.alignment = .left
                paragraphLeft.lineBreakMode = .byWordWrapping

                let paragraphRight = NSMutableParagraphStyle()
                paragraphRight.alignment = .right
                paragraphRight.lineBreakMode = .byWordWrapping

                let keyAttributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.darkGray,
                    .paragraphStyle: paragraphLeft
                ]

                let valueAttributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: paragraphRight
                ]

                let keyAttr = NSAttributedString(string: key, attributes: keyAttributes)
                let valueAttr = NSAttributedString(string: value, attributes: valueAttributes)

                let maxWidth = pageRect.width - 2 * padding
                let valueMaxWidth = maxWidth * 0.45
                let keyMaxWidth = maxWidth - valueMaxWidth - 8

                let keySize = keyAttr.boundingRect(
                    with: CGSize(width: keyMaxWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                )

                let valueSize = valueAttr.boundingRect(
                    with: CGSize(width: valueMaxWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                )

                let rowHeight = max(keySize.height, valueSize.height)

                keyAttr.draw(
                    in: CGRect(
                        x: padding,
                        y: y,
                        width: keyMaxWidth,
                        height: rowHeight
                    )
                )

                valueAttr.draw(
                    in: CGRect(
                        x: pageRect.width - padding - valueMaxWidth,
                        y: y,
                        width: valueMaxWidth,
                        height: rowHeight
                    )
                )

                y += rowHeight + 2
            }
            
            func drawLinkText(_ text: String, font: UIFont) -> CGRect {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                paragraphStyle.lineBreakMode = .byCharWrapping

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.systemBlue,
                    .paragraphStyle: paragraphStyle
                ]

                let attributed = NSAttributedString(string: text, attributes: attributes)

                let size = attributed.boundingRect(
                    with: CGSize(width: pageRect.width - 2 * padding, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                )

                let rect = CGRect(
                    x: padding,
                    y: y,
                    width: pageRect.width - 2 * padding,
                    height: size.height
                )

                attributed.draw(in: rect)
                y += size.height + 4
                return rect
            }

            // MARK: - Fonts

            let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
            let subtitleFont = UIFont.systemFont(ofSize: 11, weight: .regular)

            let sectionTitleFont = UIFont.systemFont(ofSize: 16, weight: .bold)
            let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            let smallFont = UIFont.systemFont(ofSize: 10, weight: .regular)

            // MARK: - Date Formatting

            let utcFormatter = ISO8601DateFormatter()
            utcFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            utcFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let utcString = utcFormatter.string(from: result.timestamp)

            let localFormatter = DateFormatter()
            localFormatter.dateStyle = .medium
            localFormatter.timeStyle = .medium
            localFormatter.locale = Locale.current
            localFormatter.timeZone = TimeZone.current
            let localString = localFormatter.string(from: metadata.localTime)

            // MARK: - Institutional Header (fixed, premium layout)

            let headerHeight: CGFloat = 86
            let headerY = y

            // Soft gray background
            drawFilledRect(
                x: 0,
                y: headerY,
                width: pageRect.width,
                height: headerHeight,
                color: UIColor(white: 0.95, alpha: 1.0)
            )

            // Title
            drawTextInRect(
                L("pdf_header_title"),
                rect: CGRect(x: padding, y: headerY + 10, width: pageRect.width - 2*padding, height: 26),
                font: titleFont,
                color: .black,
                alignment: .center,
                lineSpacing: 0
            )

            // Subtitle
            drawTextInRect(
                L("pdf_header_subtitle"),
                rect: CGRect(x: padding, y: headerY + 38, width: pageRect.width - 2*padding, height: 18),
                font: subtitleFont,
                color: .darkGray,
                alignment: .center,
                lineSpacing: 0
            )

            // Evidence line
            drawTextInRect(
                String(format: L("pdf_header_evidence_line_format"), metadata.evidenceID.uuidString, utcString),
                rect: CGRect(x: padding, y: headerY + 58, width: pageRect.width - 2*padding, height: 16),
                font: UIFont.systemFont(ofSize: 9, weight: .regular),
                color: .darkGray,
                alignment: .center,
                lineSpacing: 0
            )

            // Advance document cursor below the header
            y = headerY + headerHeight + 10
            drawLine(spacingBefore: 6, spacingAfter: 14)


            // MARK: - Hero Result Card (visual priority)

            let cardHeight: CGFloat = 86
            let cardY = y

            drawFilledRect(
                x: padding,
                y: cardY,
                width: pageRect.width - 2*padding,
                height: cardHeight,
                color: UIColor(white: 0.98, alpha: 1.0)
            )

            // Status (localized)
            let statusKeyHero: String
            switch result.stabilityStatus {
            case .good:     statusKeyHero = "pdf_status_stable"
            case .unstable: statusKeyHero = "pdf_status_unstable"
            case .poor:     statusKeyHero = "pdf_status_warning"
            }
            let heroStatus = L(statusKeyHero)

            // Line 1: Large STATUS
            drawTextInRect(
                heroStatus.uppercased(),
                rect: CGRect(x: padding, y: cardY + 14, width: pageRect.width - 2*padding, height: 30),
                font: UIFont.systemFont(ofSize: 22, weight: .bold),
                color: .black,
                alignment: .center,
                lineSpacing: 0
            )

            // Line 2: Large SCORE
            drawTextInRect(
                "\(result.stabilityScore)/100",
                rect: CGRect(x: padding, y: cardY + 48, width: pageRect.width - 2*padding, height: 22),
                font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                color: .darkGray,
                alignment: .center,
                lineSpacing: 0
            )

            y = cardY + cardHeight + 10
            drawLine(spacingBefore: 8, spacingAfter: 12)


            // MARK: - Identification Section

            drawText(L("pdf_section_identification"), font: sectionTitleFont)
            drawLine(spacingBefore: 2, spacingAfter: 10)

            drawKeyValueRow(
                key: L("pdf_field_evidence_id"),
                value: metadata.evidenceID.uuidString,
                font: bodyFont
            )

            drawKeyValueRow(
                key: L("pdf_field_generated_utc"),
                value: utcString,
                font: bodyFont
            )

            drawKeyValueRow(
                key: String(format: L("pdf_field_local_time_tz_format"), metadata.timeZoneIdentifier),
                value: localString,
                font: bodyFont
            )

            drawKeyValueRow(
                key: L("pdf_field_device"),
                value: String(
                    format: L("pdf_device_value_format"),
                    metadata.deviceModel,
                    "iOS",
                    metadata.systemVersion
                ),
                font: bodyFont
            )

            drawKeyValueRow(
                key: L("pdf_field_app_version"),
                value: metadata.appVersion,
                font: bodyFont
            )

            drawLine()


            // MARK: - Test Summary Section

            drawText(L("pdf_section_test_summary"), font: sectionTitleFont)

            let host = result.config.targetURL.host ?? result.config.targetURL.absoluteString

            drawKeyValueRow(
                key: L("pdf_field_target_host"),
                value: host,
                font: bodyFont
            )
            
            // Stability status (localized)
            let statusKey: String
            switch result.stabilityStatus {
            case .good:     statusKey = "pdf_status_stable"
            case .unstable: statusKey = "pdf_status_unstable"
            case .poor:     statusKey = "pdf_status_warning"
            }

            let statusText = L(statusKey)

            drawKeyValueRow(
                key: L("pdf_field_status_score"),
                value: "\(statusText) • \(Int(result.stabilityScore))/100",
                font: bodyFont
            )

            // Connection type (localized)
            let connText = L(result.networkContext.connectionType.pdfLocalizedKey)
            drawKeyValueRow(
                key: L("pdf_field_connection_type"),
                value: connText,
                font: bodyFont
            )

            drawLine()
            
            // MARK: - Network Environment

            drawText(L("pdf_section_network_environment"), font: sectionTitleFont)

            let ctx = result.networkContext

            switch ctx.connectionType {
            case .wifi:
                if let ssid = ctx.wifiSSIDMasked {
                    drawKeyValueRow(key: L("pdf_wifi_ssid_masked"), value: ssid, font: bodyFont)
                }
                if let bssid = ctx.wifiBSSIDMasked {
                    drawKeyValueRow(key: L("pdf_wifi_bssid_masked"), value: bssid, font: bodyFont)
                }
                if let band = ctx.wifiBand {
                    drawKeyValueRow(key: L("pdf_wifi_band"), value: band, font: bodyFont)
                }
                if let channel = ctx.wifiChannel {
                    drawKeyValueRow(key: L("pdf_wifi_channel"), value: String(format: L("pdf_format_int"), channel), font: bodyFont)
                }
                if let rssi = ctx.wifiRSSI {
                    drawKeyValueRow(key: L("pdf_wifi_rssi"), value: String(format: L("pdf_format_dbm_int"), rssi), font: bodyFont)
                }

                if ctx.wifiSSIDMasked == nil &&
                    ctx.wifiBSSIDMasked == nil &&
                    ctx.wifiBand == nil &&
                    ctx.wifiChannel == nil &&
                    ctx.wifiRSSI == nil {
                    drawText(L("pdf_wifi_privacy_note"), font: smallFont, color: .darkGray)
                }

            case .cellular:
                drawText(L("pdf_cellular_privacy_note"), font: smallFont, color: .darkGray)

            default:
                drawText(L("pdf_env_no_details"), font: smallFont, color: .darkGray)
            }

            drawLine()

            // MARK: - Metrics (Table)

            drawText(L("pdf_section_metrics"), font: sectionTitleFont)

            drawKeyValueRow(
                key: L("pdf_metric_avg_latency"),
                value: String(format: L("pdf_format_ms_1f"), result.avgLatencyMs),
                font: bodyFont
            )

            drawKeyValueRow(
                key: L("pdf_metric_min_latency"),
                value: String(format: L("pdf_format_ms_1f"), result.minLatencyMs),
                font: bodyFont
            )

            drawKeyValueRow(
                key: L("pdf_metric_max_latency"),
                value: String(format: L("pdf_format_ms_1f"), result.maxLatencyMs),
                font: bodyFont
            )

            drawKeyValueRow(
                key: L("pdf_metric_jitter"),
                value: String(format: L("pdf_format_ms_1f"), result.jitterMs),
                font: bodyFont
            )

            drawKeyValueRow(
                key: L("pdf_metric_packet_loss"),
                value: String(format: L("pdf_format_percent_1f"), result.packetLossPercent),
                font: bodyFont
            )

            drawKeyValueRow(
                key: L("pdf_metric_total_samples"),
                value: "\(result.totalSamples)",
                font: bodyFont
            )

            drawKeyValueRow(
                key: L("pdf_metric_failed_samples"),
                value: "\(result.failedSamples)",
                font: bodyFont
            )

            drawLine()
            
            // MARK: - Samples (per-packet data)

            drawText(L("pdf_section_samples"), font: sectionTitleFont)

            if samples.isEmpty {
                drawText(L("pdf_samples_empty"), font: smallFont, color: .darkGray)
            } else {

                drawText(L("pdf_samples_row_explainer"), font: smallFont, color: .darkGray)

                let sampleFormatter = ISO8601DateFormatter()
                sampleFormatter.timeZone = TimeZone(abbreviation: "UTC")
                sampleFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                for sample in samples {
                    let ts = sampleFormatter.string(from: sample.startTime)

                    let latencyStr: String
                    if let latency = sample.latencyMs {
                        latencyStr = String(format: L("pdf_samples_latency_ms_format"), latency)
                    } else {
                        latencyStr = L("pdf_samples_latency_na")
                    }

                    let successStr = sample.success ? L("pdf_samples_ok") : L("pdf_samples_fail")

                    // Linha formatada e localizável
                    let line = String(
                        format: L("pdf_samples_line_format"),
                        sample.index,
                        ts,
                        latencyStr,
                        successStr
                    )

                    drawText(line, font: smallFont)
                }
            }

            drawLine()

            // MARK: - Methodology (detailed)

            drawText(
                L("pdf_methodology_title"),
                font: sectionTitleFont, color: .darkGray
            )

            drawText(L("pdf_methodology_formal_title"), font: bodyFont, color: .darkGray)
            drawText(L("pdf_methodology_formal_body"), font: smallFont, color: .darkGray)
            drawLine(spacingBefore: 8, spacingAfter: 12)

            // 1) Objective measurement parameters (packet count, interval, timeout)
            drawKeyValueRow(
                key: L("pdf_method_packets_count"),
                value: "\(result.config.sampleCount)",
                font: bodyFont
            )

            drawKeyValueRow(
                key: L("pdf_method_packets_interval"),
                value: "\(result.config.intervalMs) ms",
                font: bodyFont
            )

            drawKeyValueRow(
                key: L("pdf_method_timeout_per_packet"),
                value: String(format: "%.1f s", result.config.timeoutSeconds),
                font: bodyFont
            )

            let safeModeText = L(result.config.mode.pdfKey)

            drawKeyValueRow(
                key: L("pdf_method_mode"),
                value: safeModeText,
                font: bodyFont
            )


            drawKeyValueRow(
                key: L("pdf_method_request_method"),
                value: L("pdf_method_request_method_value"),
                font: bodyFont
            )

            // 2) Measurement procedure explanation
            let procedure = String(
                format: L("pdf_method_measurement_procedure_format"),
                result.config.sampleCount
            )

            drawText(
                procedure,
                font: smallFont,
                color: .darkGray
            )

            // 3) Jitter interpretation
            let jitterValue = result.jitterMs
            let jitterInterpretationKey: String

            if jitterValue < 10 {
                jitterInterpretationKey = "pdf_jitter_interp_low"
            } else if jitterValue < 30 {
                jitterInterpretationKey = "pdf_jitter_interp_moderate"
            } else {
                jitterInterpretationKey = "pdf_jitter_interp_high"
            }

            let jitterBlock = String(
                format: L("pdf_jitter_interp_block_format"),
                String(format: "%.1f ms", jitterValue),
                L(jitterInterpretationKey)
            )

            drawText(
                jitterBlock,
                font: smallFont,
                color: .darkGray
            )

            // 4) Stability score formula explanation
            drawText(
                L("pdf_score_formula_body"),
                font: smallFont,
                color: .darkGray
            )

            drawLine()
            
            // MARK: - Result Interpretation

            drawText(L("pdf_section_result_interpretation"), font: sectionTitleFont)

            // Latency interpretation
            let avg = result.avgLatencyMs
            let latencyTextKey: String
            if avg < 50 {
                latencyTextKey = "pdf_latency_assessment_low"
            } else if avg < 100 {
                latencyTextKey = "pdf_latency_assessment_moderate"
            } else if avg < 200 {
                latencyTextKey = "pdf_latency_assessment_high"
            } else {
                latencyTextKey = "pdf_latency_assessment_very_high"
            }

            drawKeyValueRow(
                key: L("pdf_field_latency_assessment"),
                value: L(latencyTextKey),
                font: smallFont
            )

            // Packet loss interpretation
            let loss = result.packetLossPercent
            let lossTextKey: String
            if loss < 1 {
                lossTextKey = "pdf_loss_assessment_none"
            } else if loss < 3 {
                lossTextKey = "pdf_loss_assessment_light"
            } else {
                lossTextKey = "pdf_loss_assessment_significant"
            }

            drawKeyValueRow(
                key: L("pdf_field_packet_loss_assessment"),
                value: L(lossTextKey),
                font: smallFont
            )

            let jitter = result.jitterMs
            let jitterTextKey: String
            if jitter < 10 {
                jitterTextKey = "pdf_jitter_assessment_low"
            } else if jitter < 30 {
                jitterTextKey = "pdf_jitter_assessment_moderate"
            } else {
                jitterTextKey = "pdf_jitter_assessment_high"
            }

            drawKeyValueRow(
                key: L("pdf_field_jitter_assessment"),
                value: L(jitterTextKey),
                font: smallFont
            )


            // Global stability conclusion
            let score = result.stabilityScore
            let finalTextKey: String
            if score >= 85 {
                finalTextKey = "pdf_conclusion_excellent"
            } else if score >= 60 {
                finalTextKey = "pdf_conclusion_good"
            } else if score >= 40 {
                finalTextKey = "pdf_conclusion_poor"
            } else {
                finalTextKey = "pdf_conclusion_severe"
            }

            drawLine(spacingBefore: 10, spacingAfter: 10)

            drawText(
                L("pdf_section_conclusion"),
                font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                color: .darkGray,
                alignment: .center
            )

            drawText(
                L(finalTextKey),
                font: UIFont.systemFont(ofSize: 12, weight: .regular),
                color: .black,
                alignment: .center,
                lineSpacing: 3
            )

            drawLine()

            // MARK: - Result Interpretation

            drawText(L("pdf_section_data_integrity"), font: sectionTitleFont)
            
            drawText(L("pdf_integrity_hash_label"), font: bodyFont)

            drawText(result.dataHash, font: smallFont, color: .darkGray)

            drawText(L("pdf_integrity_tamper_note"), font: smallFont, color: .darkGray)

            drawLine()

            drawText(L("pdf_section_evidence_signature"), font: sectionTitleFont)


            if let signature = signature {
                drawKeyValueRow(
                    key: L("pdf_signature_algorithm"),
                    value: signature.algorithm,
                    font: bodyFont
                )

                drawText(L("pdf_signature_value_base64"), font: smallFont, color: .darkGray)
                drawText(signature.value, font: smallFont, color: .darkGray)

                drawText(L("pdf_signature_public_key_pem"), font: smallFont, color: .darkGray)
                drawText(signature.publicKeyPEM, font: smallFont, color: .darkGray)
            } else {
                drawText(
                    L("pdf_signature_missing_note"),
                    font: smallFont,
                    color: .darkGray
                )
            }

            drawLine()

            // MARK: - Disclaimer

            drawText(L("pdf_section_disclaimer"), font: sectionTitleFont)

            drawText(
                L("pdf_disclaimer_body"),
                font: smallFont,
                color: .darkGray
            )

            drawText(L("pdf_disclaimer_offline_note"), font: smallFont, color: .darkGray)
            
            drawLine(spacingBefore: 10, spacingAfter: 0)
            
            context.beginPage()

            y = padding
            drawText(L("pdf_section_verification"), font: sectionTitleFont, alignment: .center)
            drawLine(spacingBefore: 8, spacingAfter: 16)

            drawText(L("pdf_verification_hash_label"), font: bodyFont)
            drawText(result.dataHash, font: smallFont, color: .darkGray)
            drawLine(spacingBefore: 8, spacingAfter: 12)

            // How-to validate (step-by-step)
            drawText(L("pdf_verification_howto_title"), font: bodyFont)
            drawText(L("pdf_verification_howto_body"), font: smallFont, color: .darkGray)
            drawLine(spacingBefore: 8, spacingAfter: 12)

            // Offline + deterministic + tamper-evident statement
            drawText(L("pdf_verification_integrity_title"), font: bodyFont)
            drawText(L("pdf_verification_integrity_body"), font: smallFont, color: .darkGray)
            drawLine(spacingBefore: 10, spacingAfter: 12)

            // QR code + QR explanation
            drawText(L("pdf_verification_scan_qr"), font: bodyFont, alignment: .center)

            // QR code (capture rect on Page 2)
            if let rect = drawQRCode(verificationURLString, size: 180) {
                qrRectOnPage2 = rect
            }

            // Link text (capture rect on Page 2)
            drawText(L("pdf_verification_open_link"), font: smallFont, color: .darkGray, alignment: .center)
            let linkRect = drawLinkText(verificationURLString, font: smallFont)
            linkTextRectOnPage2 = linkRect

            drawText(L("pdf_verification_qr_explainer"), font: smallFont, color: .darkGray, alignment: .center)
        }

        // ost-processing: Make QR and link text clickable (link annotation) on Page 2
        if let doc = PDFDocument(data: data),
           let page2 = doc.page(at: 1) {

            // UIKit (top-left) to PDFKit (bottom-left) coordinate conversion
            func toPDFRect(_ r: CGRect) -> CGRect {
                CGRect(
                    x: r.origin.x,
                    y: pageRect.height - r.origin.y - r.size.height,
                    width: r.size.width,
                    height: r.size.height
                )
            }

            if let qrRect = qrRectOnPage2 {
                let ann = PDFAnnotation(bounds: toPDFRect(qrRect), forType: .link, withProperties: nil)
                ann.url = verificationURL
                ann.border = PDFBorder()
                page2.addAnnotation(ann)
            }

            if let linkRect = linkTextRectOnPage2 {
                let ann2 = PDFAnnotation(bounds: toPDFRect(linkRect), forType: .link, withProperties: nil)
                ann2.url = verificationURL
                ann2.border = PDFBorder()
                page2.addAnnotation(ann2)
            }

            if let out = doc.dataRepresentation() {
                return out
            }
        }

        return data
    }
}
