import Foundation

/// DTOs de la iTunes Search API. Todo opcional salvo lo imprescindible: la API no es consistente.
struct ResponseDTO: Decodable, Sendable {
    let results: [ItemDTO]
}

/// Un elemento de `results`: álbum (`wrapperType == "collection"`) o canción (`"track"`).
struct ItemDTO: Decodable, Sendable {
    let wrapperType: String?
    let collectionId: Int?
    let collectionName: String?
    let artistName: String?
    let artworkUrl100: String?
    let primaryGenreName: String?
    let releaseDate: String?
    let trackCount: Int?
    let collectionPrice: Double?
    let currency: String?
    let country: String?
    let copyright: String?
    let collectionViewUrl: String?
    let trackId: Int?
    let trackNumber: Int?
    let trackName: String?
    let trackTimeMillis: Int?
}
