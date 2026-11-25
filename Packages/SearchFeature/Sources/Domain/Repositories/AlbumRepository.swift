import Foundation

public protocol AlbumRepository: Sendable {
    func searchAlbums(query: String) async throws -> [Album]
    func albumDetail(id: Int) async throws -> AlbumDetail
}
