import SwiftUI

/// Estado de error con botón «Reintentar». `message` llega ya localizado desde el ViewModel.
struct ErrorStateView: View {
    let message: String
    var retryIdentifier = "retry-button"
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label {
                Text("state.error.title", bundle: .module)
            } icon: {
                Image(systemName: "exclamationmark.triangle")
            }
        } description: {
            Text(verbatim: message)
        } actions: {
            Button(action: retry) {
                Text("state.error.retry", bundle: .module)
                    .frame(minHeight: Metrics.minTapTarget)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier(retryIdentifier)
            // Voice Control: formas alternativas de nombrar el botón.
            .accessibilityInputLabels([
                String(localized: "state.error.retry", bundle: .module),
                String(localized: "state.error.retry.alt", bundle: .module),
            ])
        }
    }
}

#Preview("Error") {
    ErrorStateView(message: "No se pudo conectar. Comprueba tu conexión e inténtalo de nuevo.") {}
}

#Preview("Error · oscuro · texto grande") {
    ErrorStateView(message: "No se pudo conectar. Comprueba tu conexión e inténtalo de nuevo.") {}
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Vacío") {
    EmptyStateView(title: "search.title", systemImage: "magnifyingglass")
}
