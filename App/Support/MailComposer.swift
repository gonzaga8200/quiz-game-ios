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
        if MFMailComposeViewController.canSendMail(), let presenter = UIApplication.shared.topViewController {
            let composer = MFMailComposeViewController()
            composer.mailComposeDelegate = self
            composer.setToRecipients([draft.to])
            composer.setSubject(draft.subject)
            composer.setMessageBody(draft.body, isHTML: false)
            return await withCheckedContinuation { continuation in
                self.continuation = continuation
                presenter.present(composer, animated: true)
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

/// Records drafts instead of opening mail (UI tests show the last subject on screen).
@Observable
final class FakeMailComposer: MailComposer {
    private(set) var drafts: [MailDraft] = []

    func compose(_ draft: MailDraft) async -> Bool {
        drafts.append(draft)
        return true
    }
}
