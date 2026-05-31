import Foundation
import UIKit

/// Engine responsible for generating PDF documents that visualize aggregate usage metrics.
final class UsageSummaryPDFEngine {

    /// Generates a PDF data representation based on the provided analytics funnel.
    /// - Parameter funnel: The analytics funnel containing usage metrics.
    /// - Returns: The generated PDF data.
    static func generate(funnel: AnalyticsFunnel) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))

        return renderer.pdfData { ctx in
            ctx.beginPage()

            let title = "Usage Summary"
            title.draw(at: CGPoint(x: 40, y: 40), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 20)
            ])

            let body = """
            Tests started: \(funnel.testsStarted)
            Tests completed: \(funnel.testsCompleted)
            Exports tapped: \(funnel.exportsTapped)
            Exports succeeded: \(funnel.exportsSucceeded)
            Share sheet shown: \(funnel.shareSheetShown)
            """

            body.draw(
                in: CGRect(x: 40, y: 100, width: 500, height: 600),
                withAttributes: [.font: UIFont.systemFont(ofSize: 14)]
            )
        }
    }
}
