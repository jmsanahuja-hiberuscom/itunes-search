import Foundation

/// Abstracción mínima sobre la red para poder sustituirla por un mock en los tests.
public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
