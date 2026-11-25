import SwiftUI

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Palette.cardBackground,
                in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
            )
    }
}

extension View {
    /// Tarjeta del design system: fondo secundario, esquinas continuas y ancho completo.
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

#Preview("Tarjeta") {
    VStack(alignment: .leading, spacing: Spacing.xxs) {
        Text(verbatim: "Motomami").font(.headline)
        Text(verbatim: "Rosalía").font(.subheadline).foregroundStyle(.secondary)
    }
    .cardStyle()
    .padding(Spacing.m)
}

#Preview("Tarjeta · oscuro · texto grande") {
    VStack(alignment: .leading, spacing: Spacing.xxs) {
        Text(verbatim: "Motomami").font(.headline)
        Text(verbatim: "Rosalía").font(.subheadline).foregroundStyle(.secondary)
    }
    .cardStyle()
    .padding(Spacing.m)
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility3)
}
