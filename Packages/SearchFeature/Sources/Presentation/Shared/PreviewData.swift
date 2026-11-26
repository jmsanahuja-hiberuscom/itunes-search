#if DEBUG
import Domain
import Foundation

/// Datos de ejemplo para las previews. Sin red: la carátula usa un placeholder.
enum PreviewData {
    static let album = Album(
        id: 1,
        title: "Un Verano Sin Ti",
        artistName: "Bad Bunny",
        artworkURL: nil,
        genre: "Reggaeton",
        releaseDate: Date(timeIntervalSince1970: 1_653_868_800),
        trackCount: 3
    )

    static let albums = [
        album,
        Album(id: 2, title: "Motomami", artistName: "Rosalía", genre: "Pop",
              releaseDate: Date(timeIntervalSince1970: 1_647_043_200), trackCount: 16),
        Album(id: 3, title: "OK Computer OKNOTOK 1997 2017 (Collector's Edition)", artistName: "Radiohead",
              genre: "Alternative", releaseDate: Date(timeIntervalSince1970: 1_495_152_000), trackCount: 23),
    ]

    static let detail = AlbumDetail(
        album: album,
        price: 9.99,
        currency: "EUR",
        country: "ESP",
        copyright: "℗ 2022 Rimas Entertainment LLC",
        storeURL: URL(string: "https://music.apple.com/album/1"),
        tracks: [
            Track(id: 1, number: 1, name: "Moscow Mule", duration: .seconds(245)),
            Track(id: 2, number: 2, name: "Después de la Playa", duration: .seconds(231)),
            Track(id: 3, number: 3, name: "Me Porto Bonito", duration: .seconds(178)),
        ]
    )
}

struct PreviewSearchAlbums: SearchAlbumsUseCase {
    var result: Result<[Album], DomainError> = .success(PreviewData.albums)
    func execute(query: String) async throws -> [Album] { try result.get() }
}

struct PreviewGetAlbumDetail: GetAlbumDetailUseCase {
    var result: Result<AlbumDetail, DomainError> = .success(PreviewData.detail)
    func execute(id: Int) async throws -> AlbumDetail { try result.get() }
}

/// Use case que no termina nunca: deja la preview en estado de carga.
struct PreviewNeverFinishes: SearchAlbumsUseCase, GetAlbumDetailUseCase {
    func execute(query: String) async throws -> [Album] {
        try await Task.sleep(for: .seconds(3600))
        return []
    }

    func execute(id: Int) async throws -> AlbumDetail {
        try await Task.sleep(for: .seconds(3600))
        return PreviewData.detail
    }
}
#endif
