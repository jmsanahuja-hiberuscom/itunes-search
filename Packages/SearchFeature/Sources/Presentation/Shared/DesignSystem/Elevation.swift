import SwiftUI

/// Sombra reutilizable. Sutil en filas, más marcada en la cabecera hero.
struct Elevation: Sendable {
    let radius: CGFloat
    let y: CGFloat
    let opacity: Double

    static let none = Elevation(radius: 0, y: 0, opacity: 0)
    static let subtle = Elevation(radius: 3, y: 1, opacity: 0.18)
    static let prominent = Elevation(radius: 16, y: 8, opacity: 0.25)
}

extension View {
    func elevation(_ elevation: Elevation) -> some View {
        shadow(
            color: Palette.shadow.opacity(elevation.opacity),
            radius: elevation.radius,
            y: elevation.y
        )
    }
}
