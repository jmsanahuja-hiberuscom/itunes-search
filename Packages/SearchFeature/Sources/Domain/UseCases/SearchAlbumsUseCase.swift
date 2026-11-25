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
        // Regla de negocio: no se busca texto vacío.
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }
        // CancellationError y DomainError se propagan tal cual.
        return try await repository.searchAlbums(query: normalized)
    }
}
