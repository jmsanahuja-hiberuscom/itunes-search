import SwiftUI

/// Estado vacío o informativo reutilizable, sobre `ContentUnavailableView`.
struct EmptyStateView<Actions: View>: View {
    let title: LocalizedStringKey
    let systemImage: String
    var message: LocalizedStringKey?
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title, bundle: .module)
            } icon: {
                Image(systemName: systemImage)
            }
        } description: {
            if let message {
                Text(message, bundle: .module)
            }
        } actions: {
            actions()
        }
    }
}

extension EmptyStateView where Actions == EmptyView {
    init(title: LocalizedStringKey, systemImage: String, message: LocalizedStringKey? = nil) {
        self.init(title: title, systemImage: systemImage, message: message) { EmptyView() }
    }
}
