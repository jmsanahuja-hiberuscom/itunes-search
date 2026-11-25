import Foundation

public struct AlbumDetail: Equatable, Sendable {
    public let album: Album
    public let price: Decimal?
    public let currency: String?
    public let country: String?
    public let copyright: String?
    public let storeURL: URL?
    public let tracks: [Track]

    public init(
        album: Album,
        price: Decimal? = nil,
        currency: String? = nil,
        country: String? = nil,
        copyright: String? = nil,
        storeURL: URL? = nil,
        tracks: [Track] = []
    ) {
        self.album = album
        self.price = price
        self.currency = currency
        self.country = country
        self.copyright = copyright
        self.storeURL = storeURL
        self.tracks = tracks
    }
}
