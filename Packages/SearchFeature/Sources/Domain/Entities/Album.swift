import Foundation

public struct Album: Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let artistName: String
    public let artworkURL: URL?
    public let genre: String?
    public let releaseDate: Date?
    public let trackCount: Int?

    public init(
        id: Int,
        title: String,
        artistName: String,
        artworkURL: URL? = nil,
        genre: String? = nil,
        releaseDate: Date? = nil,
        trackCount: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artworkURL = artworkURL
        self.genre = genre
        self.releaseDate = releaseDate
        self.trackCount = trackCount
    }
}
