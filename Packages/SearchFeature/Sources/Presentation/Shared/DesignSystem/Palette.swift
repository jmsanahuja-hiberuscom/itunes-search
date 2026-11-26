import SwiftUI

/// Colores semánticos del sistema. Único sitio donde se nombran colores;
/// el acento de marca vive en el `AccentColor` del Asset Catalog de la app.
enum Palette {
    static let shadow = Color.black

    #if canImport(UIKit)
    static let background = Color(.systemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemBackground)
    static let placeholderFill = Color(.tertiarySystemFill)
    static let placeholderSymbol = Color(.secondaryLabel)
    #else
    // Solo para que el paquete compile en macOS (`swift test` construye todos los targets).
    // La app es exclusivamente iOS.
    static let background = Color(nsColor: .windowBackgroundColor)
    static let groupedBackground = Color(nsColor: .underPageBackgroundColor)
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
    static let placeholderFill = Color(nsColor: .quaternaryLabelColor)
    static let placeholderSymbol = Color(nsColor: .secondaryLabelColor)
    #endif
}

/// Métricas base (antes de escalar con `@ScaledMetric`).
enum Metrics {
    /// Lado del artwork en las filas de resultados.
    static let rowArtwork: CGFloat = 64
    /// Área táctil mínima recomendada por Apple.
    static let minTapTarget: CGFloat = 44
    /// Ancho máximo de lectura cómodo en listas (horizontal, iPhone grandes).
    static let readingWidth: CGFloat = 640
    /// Lado máximo del artwork hero.
    static let heroArtworkMax: CGFloat = 400
}
