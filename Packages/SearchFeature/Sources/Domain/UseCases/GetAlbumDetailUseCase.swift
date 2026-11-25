import Foundation

public protocol GetAlbumDetailUseCase: Sendable {
    func execute(id: Int) async throws -> AlbumDetail
}

public struct DefaultGetAlbumDetailUseCase: GetAlbumDetailUseCase {
    private let repository: any AlbumRepository

    public init(repository: any AlbumRepository) {
        self.repository = repository
    }

    public func execute(id: Int) async throws -> AlbumDetail {
        try await repository.albumDetail(id: id)
    }
}
