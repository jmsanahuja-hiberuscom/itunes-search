import Foundation
import os

/// `URLProtocol` que acepta la petición y nunca responde: deja la petición «en vuelo»
/// para comprobar con un `URLSession` real que cancelar la tarea la detiene de verdad.
/// Los avisos se registran por URL para que los tests no se pisen entre sí.
final class HangingURLProtocol: URLProtocol, @unchecked Sendable {
    struct Hooks: Sendable {
        let onStart: @Sendable () -> Void
        let onStop: @Sendable () -> Void
    }

    private static let hooks = OSAllocatedUnfairLock(initialState: [URL: Hooks]())

    static func register(for url: URL, _ newHooks: Hooks) {
        hooks.withLock { $0[url] = newHooks }
    }

    private var registered: Hooks? {
        guard let url = request.url else { return nil }
        return Self.hooks.withLock { $0[url] }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        registered?.onStart()
    }

    override func stopLoading() {
        registered?.onStop()
    }
}
