import Foundation

/// Estado de una pantalla que carga datos. `Equatable` para poder compararlo en tests.
public enum ViewState<T: Equatable>: Equatable {
    case idle
    case loading
    case loaded(T)
    case empty
    /// `message` ya está localizado y listo para mostrarse al usuario.
    case failed(message: String)
}

extension ViewState: Sendable where T: Sendable {}
