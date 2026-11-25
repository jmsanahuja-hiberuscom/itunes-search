import Domain

/// Use case de detalle falso: devuelve resultados predefinidos (en orden, repitiendo el último)
/// y registra los ids recibidos.
actor MockGetAlbumDetailUseCase: GetAlbumDetailUseCase {
    private(set) var ids: [Int] = []
    private var results: [Result<AlbumDetail, any Error>]

    init(results: [Result<AlbumDetail, any Error>]) {
        self.results = results
    }

    func execute(id: Int) async throws -> AlbumDetail {
        ids.append(id)
        let result = results.count > 1 ? results.removeFirst() : results[0]
        return try result.get()
    }
}

extension AlbumDetail {
    static func fixture(album: Album = .fixture()) -> AlbumDetail {
        AlbumDetail(
            album: album,
            price: 9.99,
            currency: "EUR",
            country: "ESP",
            tracks: [Track(id: 10, number: 1, name: "Saoko", duration: .seconds(137))]
        )
    }
}
