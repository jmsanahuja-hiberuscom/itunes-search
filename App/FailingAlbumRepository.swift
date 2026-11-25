import Domain

/// Repositorio para ver y testear los estados de error sin red (`-UITestMockError`).
/// El detalle siempre falla. La búsqueda falla salvo que se le pase `searchSource`
/// (el modo combinado con `-UITestMockData`: se puede buscar, pero abrir un álbum da error).
struct FailingAlbumRepository: AlbumRepository {
    private let searchSource: (any AlbumRepository)?

    init(searchSource: (any AlbumRepository)? = nil) {
        self.searchSource = searchSource
    }

    func searchAlbums(query: String) async throws -> [Album] {
        guard let searchSource else { throw DomainError.network }
        return try await searchSource.searchAlbums(query: query)
    }

    func albumDetail(id: Int) async throws -> AlbumDetail {
        throw DomainError.network
    }
}
