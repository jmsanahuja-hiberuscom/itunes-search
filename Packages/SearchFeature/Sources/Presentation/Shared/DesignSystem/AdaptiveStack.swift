import SwiftUI

/// `HStack` que pasa a `VStack` con los tamaños de texto de accesibilidad,
/// para que el contenido no se trunque ni se comprima.
struct AdaptiveStack<Content: View>: View {
    var spacing: CGFloat = Spacing.m
    @ViewBuilder var content: () -> Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: spacing, content: content)
        } else {
            HStack(alignment: .center, spacing: spacing, content: content)
        }
    }
}
