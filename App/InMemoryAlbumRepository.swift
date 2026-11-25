import Domain
import Foundation

/// Repositorio en memoria con datos fijos para los UI tests (`-UITestMockData`): sin red y determinista.
struct InMemoryAlbumRepository: AlbumRepository {
    private static let releaseDate = Date(timeIntervalSince1970: 1_653_868_800)

    private static let albums = [
        Album(id: 1, title: "Motomami", artistName: "Rosalía", genre: "Pop", releaseDate: releaseDate, trackCount: 3),
        Album(id: 2, title: "OK Computer", artistName: "Radiohead", genre: "Alternative", releaseDate: releaseDate, trackCount: 3),
        Album(id: 3, title: "Random Access Memories", artistName: "Daft Punk", genre: "Electronic", releaseDate: releaseDate, trackCount: 3),
        Album(id: 4, title: "Un Verano Sin Ti", artistName: "Bad Bunny", genre: "Reggaeton", releaseDate: releaseDate, trackCount: 3),
    ]

    func searchAlbums(query: String) async throws -> [Album] {
        Self.albums.filter {
            $0.title.localizedStandardContains(query) || $0.artistName.localizedStandardContains(query)
        }
    }

    func albumDetail(id: Int) async throws -> AlbumDetail {
        guard let album = Self.albums.first(where: { $0.id == id }) else { throw DomainError.notFound }
        return AlbumDetail(
            album: album,
            price: 9.99,
            currency: "EUR",
            country: "ESP",
            copyright: "℗ 2022 Mock Records",
            storeURL: URL(string: "https://music.apple.com/album/\(id)"),
            tracks: (1...3).map {
                Track(id: id * 100 + $0, number: $0, name: "Track \($0)", duration: .seconds(180 + $0 * 7))
            }
        )
    }
}
