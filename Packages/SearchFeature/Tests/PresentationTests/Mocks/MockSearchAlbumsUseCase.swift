import Domain

/// Use case falso: devuelve resultados predefinidos (en orden, repitiendo el último)
/// y registra las queries recibidas. Cada test crea el suyo.
actor MockSearchAlbumsUseCase: SearchAlbumsUseCase {
    private(set) var queries: [String] = []
    private var results: [Result<[Album], any Error>]

    init(results: [Result<[Album], any Error>] = [.success([])]) {
        self.results = results
    }

    func execute(query: String) async throws -> [Album] {
        queries.append(query)
        let result = results.count > 1 ? results.removeFirst() : results[0]
        return try result.get()
    }
}
