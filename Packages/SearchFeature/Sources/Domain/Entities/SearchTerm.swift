import Foundation

extension String {
    /// Texto de búsqueda normalizado: sin espacios al principio ni al final y con los
    /// espacios internos colapsados en uno. No cambia mayúsculas ni acentos.
    /// Es la única definición de «misma búsqueda» para el caso de uso, la caché y el view model.
    public var normalizedSearchTerm: String {
        split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
