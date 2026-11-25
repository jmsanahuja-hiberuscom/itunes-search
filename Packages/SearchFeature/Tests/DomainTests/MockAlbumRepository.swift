import Foundation
@testable import Domain

/// Repositorio falso que registra llamadas. Cada test crea el suyo.
actor MockAlbumRepository: AlbumRepository {
    private(set) var searchQueries: [String] = []
    private(set) var detailIDs: [Int] = []
    private let searchResult: Result<[Album], any Error>
    private let detailResult: Result<AlbumDetail, any Error>

    init(
        searchResult: Result<[Album], any Error> = .success([]),
        detailResult: Result<AlbumDetail, any Error> = .failure(DomainError.unknown)
    ) {
        self.searchResult = searchResult
        self.detailResult = detailResult
    }

    func searchAlbums(query: String) async throws -> [Album] {
        searchQueries.append(query)
        return try searchResult.get()
    }

    func albumDetail(id: Int) async throws -> AlbumDetail {
        detailIDs.append(id)
        return try detailResult.get()
    }
}

extension Album {
    static func fixture(id: Int = 1, title: String = "Motomami") -> Album {
        Album(id: id, title: title, artistName: "Rosalía")
    }
}
