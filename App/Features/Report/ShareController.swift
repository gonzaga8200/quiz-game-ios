import UIKit

/// How a result was shared, for the `share` event: "copy" when copied, "native" for any other app,
/// nil when the sheet was dismissed.
func shareMethod(for activity: UIActivity.ActivityType?, completed: Bool) -> String? {
    guard completed else { return nil }
    return activity == .copyToPasteboard ? "copy" : "native"
}

/// The system share sheet with the result text and the link (the web's navigator.share).
enum ShareController {
    static func share(text: String, url: URL, completion: @escaping (String?) -> Void) {
        guard let presenter = UIApplication.shared.topViewController else { return completion(nil) }
        let sheet = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        sheet.completionWithItemsHandler = { activity, completed, _, _ in
            completion(shareMethod(for: activity, completed: completed))
        }
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.maxY - 80, width: 1, height: 1)
            popover.permittedArrowDirections = .down
        }
        presenter.present(sheet, animated: true)
    }
}
