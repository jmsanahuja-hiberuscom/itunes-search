import Domain
import Foundation
import Testing
@testable import Data

struct MapperTests {
    @Test func searchFixtureMapsToAlbums() throws {
        let dto = try JSONDecoder().decode(ResponseDTO.self, from: Fixture.data("search"))
        let albums = dto.toAlbums()

        #expect(albums.count == 3)
        let first = try #require(albums.first)
        #expect(first.id == 1440768692)
        #expect(first.title == "In Between Dreams")
        #expect(first.artistName == "Jack Johnson")
        #expect(first.trackCount == 14)
        #expect(first.artworkURL?.absoluteString.hasSuffix("600x600bb.jpg") == true)
        let date = try #require(first.releaseDate)
        let year = Calendar(identifier: .gregorian)
            .dateComponents(in: try #require(TimeZone(identifier: "UTC")), from: date).year
        #expect(year == 2005)
    }

    @Test func lookupFixtureMapsToDetailWithSortedTracks() throws {
        let dto = try JSONDecoder().decode(ResponseDTO.self, from: Fixture.data("lookup"))
        let detail = try #require(dto.toAlbumDetail())

        #expect(detail.album.id == 1440768692)
        #expect(detail.price == Decimal(string: "9.99"))
        #expect(detail.currency == "USD")
        #expect(detail.copyright == "℗ 2005 Jack Johnson")
        #expect(detail.storeURL?.host == "music.apple.com")
        #expect(detail.tracks.map(\.number) == [1, 2, 3])
        #expect(detail.tracks.map(\.name) == ["Better Together", "Never Know", "Banana Pancakes"])
        #expect(detail.tracks.first?.duration == .milliseconds(207_680))
    }

    @Test func itemsMissingRequiredFieldsAreSkipped() throws {
        let json = Data("""
        {"resultCount":2,"results":[
          {"wrapperType":"collection","collectionId":1,"collectionName":"Ok","artistName":"A"},
          {"wrapperType":"collection","collectionName":"No id","artistName":"A"}
        ]}
        """.utf8)
        let albums = try JSONDecoder().decode(ResponseDTO.self, from: json).toAlbums()
        #expect(albums.map(\.id) == [1])
        #expect(albums.first?.artworkURL == nil)
    }

    @Test func lookupWithoutCollectionHasNoDetail() throws {
        let json = Data(#"{"resultCount":0,"results":[]}"#.utf8)
        #expect(try JSONDecoder().decode(ResponseDTO.self, from: json).toAlbumDetail() == nil)
    }
}
