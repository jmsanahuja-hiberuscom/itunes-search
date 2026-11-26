import Foundation

public protocol SearchAlbumsUseCase: Sendable {
    func execute(query: String) async throws -> [Album]
}

public struct DefaultSearchAlbumsUseCase: SearchAlbumsUseCase {
    private let repository: any AlbumRepository

    public init(repository: any AlbumRepository) {
        self.repository = repository
    }

    public func execute(query: String) async throws -> [Album] {
        // Regla de negocio: no se busca texto vacío, y la query llega normalizada.
        let normalized = query.normalizedSearchTerm
        guard !normalized.isEmpty else { return [] }
        // CancellationError y DomainError se propagan tal cual.
        let albums = try await repository.searchAlbums(query: normalized)
        // La API puede repetir un álbum: se conserva la primera aparición y el orden.
        var seen = Set<Album.ID>()
        return albums.filter { seen.insert($0.id).inserted }
    }
}
