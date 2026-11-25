import Domain
import Foundation

extension ItemDTO {
    func toAlbum() -> Album? {
        guard let collectionId, let collectionName, let artistName else { return nil }
        return Album(
            id: collectionId,
            title: collectionName,
            artistName: artistName,
            artworkURL: artworkUrl100.flatMap(Self.highResolutionArtwork),
            genre: primaryGenreName,
            releaseDate: releaseDate.flatMap { try? Date($0, strategy: .iso8601) },
            trackCount: trackCount
        )
    }

    func toTrack() -> Track? {
        guard let trackId, let trackNumber, let trackName else { return nil }
        return Track(
            id: trackId,
            number: trackNumber,
            name: trackName,
            duration: trackTimeMillis.map { .milliseconds($0) }
        )
    }

    /// `100x100` → `600x600` para mostrar el artwork con buena resolución.
    private static func highResolutionArtwork(_ value: String) -> URL? {
        URL(string: value.replacingOccurrences(of: "100x100", with: "600x600"))
    }
}

extension ResponseDTO {
    func toAlbums() -> [Album] {
        results.filter { $0.wrapperType == nil || $0.wrapperType == "collection" }
            .compactMap { $0.toAlbum() }
    }

    /// Sin álbum en la respuesta (id inexistente) → `nil`.
    func toAlbumDetail() -> AlbumDetail? {
        guard let item = results.first(where: { $0.wrapperType == "collection" }),
              let album = item.toAlbum() else { return nil }
        let tracks = results
            .filter { $0.wrapperType == "track" }
            .compactMap { $0.toTrack() }
            .sorted { $0.number < $1.number }
        return AlbumDetail(
            album: album,
            price: item.collectionPrice.flatMap { Decimal(string: String($0)) },
            currency: item.currency,
            country: item.country,
            copyright: item.copyright,
            storeURL: item.collectionViewUrl.flatMap(URL.init(string:)),
            tracks: tracks
        )
    }
}
