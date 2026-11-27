import MessageUI
import Observation
import UIKit

/// Opens the player's mail with a draft ready (contact, question and player reports). The app
/// never sends anything itself, like the web's `mailto:` links.
protocol MailComposer: AnyObject {
    /// True when a composer or mail app opened.
    func compose(_ draft: MailDraft) async -> Bool
}

/// The system composer if a mail account is set up, else the `mailto:` link, else the address is
/// copied so the player can paste it.
final class SystemMailComposer: NSObject, MailComposer, MFMailComposeViewControllerDelegate {
    private var continuation: CheckedContinuation<Bool, Never>?

    func compose(_ draft: MailDraft) async -> Bool {
        if continuation == nil, MFMailComposeViewController.canSendMail(), var presenter = UIApplication.shared.topViewController {
            // Never present on a controller that is on its way out: UIKit would drop the composer.
            while presenter.isBeingDismissed, let parent = presenter.presentingViewController { presenter = parent }
            let composer = MFMailComposeViewController()
            composer.mailComposeDelegate = self
            composer.setToRecipients([draft.to])
            composer.setSubject(draft.subject)
            composer.setMessageBody(draft.body, isHTML: false)
            return await withCheckedContinuation { continuation in
                self.continuation = continuation
                presenter.present(composer, animated: true)
                if composer.presentingViewController == nil {
                    // Refused (another presentation in progress): answer instead of waiting forever.
                    self.continuation = nil
                    continuation.resume(returning: false)
                }
            }
        }
        if await UIApplication.shared.open(draft.mailtoURL) { return true }
        UIPasteboard.general.string = draft.to
        return false
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
        controller.dismiss(animated: true)
        continuation?.resume(returning: true)
        continuation = nil
    }
}

/// Records drafts instead of opening mail (UI tests show the last subject on screen), and whether
/// a sheet was still on screen or leaving when mail was opened: the real composer would be
/// presented on it and dropped.
@Observable
final class FakeMailComposer: MailComposer {
    private(set) var drafts: [MailDraft] = []
    private(set) var openedOverSheet: [Bool] = []

    func compose(_ draft: MailDraft) async -> Bool {
        let top = UIApplication.shared.topViewController
        let sheet = top.map { [.pageSheet, .formSheet].contains($0.modalPresentationStyle) || $0.isBeingDismissed } ?? false
        drafts.append(draft)
        openedOverSheet.append(sheet)
        return true
    }
}
