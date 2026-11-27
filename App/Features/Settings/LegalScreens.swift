import SwiftUI

/// A long legal text: a title, the date and its sections.
struct LegalDocumentScreen: View {
    let title: LocalizedStringKey
    let sections: [LegalSection]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(title)
                    .font(.display(.largeTitle, weight: .heavy, italic: true))
                    .foregroundStyle(Color.accentOnGround)
                    .accessibilityAddTraits(.isHeader)
                Text("Última actualización: \(Legal.lastUpdated)").font(.reading(.footnote)).foregroundStyle(Color.onGroundSoft)
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: section.heading).font(.display(.title3, weight: .heavy, italic: true))
                            .accessibilityAddTraits(.isHeader)
                        ForEach(section.paragraphs, id: \.self) { paragraph in
                            Text(LocalizedStringKey(stringLiteral: paragraph)).font(.reading(.body)).tint(Color.accentOnGround)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.onGround)
        .background(Color.ground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyScreen: View {
    var body: some View {
        LegalDocumentScreen(title: "Política de privacidad", sections: LegalTexts.privacy)
            .trackScreen("Privacidad")
    }
}

struct LegalNoticeScreen: View {
    var body: some View {
        LegalDocumentScreen(title: "Aviso legal", sections: LegalTexts.legalNotice)
            .trackScreen("Aviso legal")
    }
}
