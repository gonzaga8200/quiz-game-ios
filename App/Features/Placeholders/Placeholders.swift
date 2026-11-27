import SwiftUI

// Temporary screens of the shell (Task 14), replaced one by one in Tasks 15 to 20.

struct TabPlaceholder: View {
    let title: LocalizedStringKey
    var body: some View {
        Text(title).font(.display(.title, weight: .heavy, italic: true))
    }
}
