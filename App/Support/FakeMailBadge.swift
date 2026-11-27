import SwiftUI

/// In UI tests, shows the subject of the last draft the fake mail composer received, so a test can
/// check what would have been sent. Nothing in a normal launch.
struct FakeMailBadge: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        if let fake = env.mail as? FakeMailComposer, let draft = fake.drafts.last {
            Text(verbatim: draft.subject)
                .font(.caption2)
                .padding(4)
                .background(.yellow)
                .accessibilityIdentifier("fakeMail.subject")
        }
    }
}
