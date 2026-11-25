import Domain

/// Use case de búsqueda cuyo resultado controla el test: cada llamada se queda
/// esperando en una `CheckedContinuation` hasta que el test la libera con `resume`.
/// Así se ordenan las respuestas a mano, sin sleeps ni carreras de tiempo.
///
/// Las queries deben ser distintas entre sí dentro de un mismo test (una pendiente por query).
actor ControllableSearchUseCase: SearchAlbumsUseCase {
    enum CancellationBehavior: Sendable {
        /// Use case «bien educado»: al cancelarse reanuda lanzando `CancellationError`.
        case throwCancellationError
        /// Use case que ignora la cancelación y devuelve resultados igualmente.
        /// Es el peor caso para el ViewModel: solo `Task.isCancelled` evita que los pinte.
        case ignore
    }

    private let cancellationBehavior: CancellationBehavior
    private var pending: [String: CheckedContinuation<[Album], any Error>] = [:]
    private var callWaiters: [String: [CheckedContinuation<Void, Never>]] = [:]
    private var calledQueries: [String] = []
    private var cancelledAtResume: [String: Bool] = [:]

    init(cancellationBehavior: CancellationBehavior = .throwCancellationError) {
        self.cancellationBehavior = cancellationBehavior
    }

    func execute(query: String) async throws -> [Album] {
        let albums = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending[query] = continuation
                calledQueries.append(query)
                for waiter in callWaiters.removeValue(forKey: query) ?? [] {
                    waiter.resume()
                }
                // Cancelada antes de llegar aquí: el handler ya se ejecutó y no encontró nada.
                if Task.isCancelled { cancel(query: query) }
            }
        } onCancel: {
            Task { await self.cancel(query: query) }
        }
        // Aquí ya estamos de vuelta en la tarea que llamó a `execute`.
        cancelledAtResume[query] = Task.isCancelled
        return albums
    }

    /// Espera (sin tiempos) a que `query` esté pendiente en el mock, lista para liberarse.
    func waitForCall(query: String) async {
        if calledQueries.contains(query) { return }
        await withCheckedContinuation { waiter in
            callWaiters[query, default: []].append(waiter)
        }
    }

    /// Libera la llamada pendiente de `query`. Devuelve `false` si no había ninguna pendiente.
    @discardableResult
    func resume(query: String, with albums: [Album]) -> Bool {
        guard let continuation = pending.removeValue(forKey: query) else { return false }
        continuation.resume(returning: albums)
        return true
    }

    /// `Task.isCancelled` de la tarea que llamó con `query` en el momento de reanudarse.
    func wasCancelledWhenResumed(query: String) -> Bool? {
        cancelledAtResume[query]
    }

    private func cancel(query: String) {
        guard cancellationBehavior == .throwCancellationError,
              let continuation = pending.removeValue(forKey: query) else { return }
        continuation.resume(throwing: CancellationError())
    }
}
