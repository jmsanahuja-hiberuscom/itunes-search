import SwiftUI

private struct MotionSafeAnimation<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation?
    let value: Value

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

extension View {
    /// Como `.animation(_:value:)`, pero sin animar si el usuario activó «Reducir movimiento».
    func motionSafeAnimation<Value: Equatable>(
        _ animation: Animation? = .default,
        value: Value
    ) -> some View {
        modifier(MotionSafeAnimation(animation: animation, value: value))
    }
}
