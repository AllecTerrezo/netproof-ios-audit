import SwiftUI

/// A SwiftUI wrapper for `UIActivityViewController` to facilitate data sharing
/// (e.g., exporting PDF evidence files or JSON usage logs).
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update logic required for this static share sheet
    }
}
