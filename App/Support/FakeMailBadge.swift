import SwiftUI

/// In UI tests, shows the subject of the last draft the fake mail composer received, so a test can
/// check what would have been sent. Nothing in a normal launch.
struct FakeMailBadge: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        if let fake = env.mail as? FakeMailComposer, let draft = fake.drafts.last {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: draft.subject)
                    .accessibilityIdentifier("fakeMail.subject")
                Text(verbatim: fake.openedOverSheet.last == true ? "overSheet: yes" : "overSheet: no")
                    .accessibilityIdentifier("fakeMail.overSheet")
            }
            .font(.caption2)
            .padding(4)
            .background(.yellow)
        }
    }
}
