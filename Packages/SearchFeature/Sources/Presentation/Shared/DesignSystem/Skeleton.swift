import SwiftUI

private struct SkeletonModifier: ViewModifier {
    let label: LocalizedStringKey
    let identifier: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dimmed = false

    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .opacity(dimmed ? 0.55 : 1)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: dimmed
            )
            .onAppear { if !reduceMotion { dimmed = true } }
            // Un único elemento para VoiceOver en lugar de leer cada placeholder.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(label, bundle: .module))
            .accessibilityIdentifier(identifier ?? "")
    }
}

extension View {
    /// Convierte la vista en un skeleton: redactada, con pulso suave (quieto con
    /// «Reducir movimiento») y expuesta como un único elemento con `label`.
    func skeleton(label: LocalizedStringKey, identifier: String? = nil) -> some View {
        modifier(SkeletonModifier(label: label, identifier: identifier))
    }
}

/// Fila placeholder con la misma estructura que una fila de resultado.
struct SkeletonRow: View {
    @ScaledMetric(relativeTo: .body) private var artworkSize = Metrics.rowArtwork

    var body: some View {
        AdaptiveStack {
            ArtworkView(url: nil, elevation: .none)
                .frame(width: artworkSize)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(verbatim: "Album title placeholder")
                    .font(.headline)
                Text(verbatim: "Artist name")
                    .font(.subheadline)
                Text(verbatim: "2024 · Genre")
                    .font(.caption)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Lista de filas placeholder, expuesta como «Cargando resultados».
struct SkeletonList: View {
    var rows = 8

    var body: some View {
        VStack(spacing: Spacing.m) {
            ForEach(0..<rows, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .padding(.horizontal, Spacing.m)
        .skeleton(label: "skeleton.loading.results", identifier: "loading-skeleton")
    }
}

#Preview("Skeleton") {
    ScrollView { SkeletonList() }
}

#Preview("Skeleton · oscuro · texto grande") {
    ScrollView { SkeletonList(rows: 3) }
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
}
