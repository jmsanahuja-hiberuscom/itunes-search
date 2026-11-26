import SwiftUI

/// Chip en cápsula con área táctil mínima de 44 pt.
struct ChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.tint)
            .padding(.horizontal, Spacing.m)
            .frame(minHeight: Metrics.minTapTarget)
            .background(Palette.cardBackground, in: Capsule())
            .opacity(configuration.isPressed ? 0.6 : 1)
            .contentShape(Capsule())
    }
}

extension ButtonStyle where Self == ChipButtonStyle {
    static var chip: ChipButtonStyle { ChipButtonStyle() }
}

#Preview("Chips") {
    FlowLayout {
        ForEach(["Rosalía", "Radiohead", "Daft Punk", "Bad Bunny"], id: \.self) { name in
            Button(name) {}.buttonStyle(.chip)
        }
    }
    .padding(Spacing.m)
}
