import Domain
import Foundation
import Testing
@testable import Data

struct DefaultAlbumRepositoryTests {
    @Test func searchMapsFixtureAndSendsRawTerm() async throws {
        let client = MockHTTPClient(data: try Fixture.data("search"))
        let sut = DefaultAlbumRepository(httpClient: client)

        let albums = try await sut.searchAlbums(query: "Jack Johnson")

        #expect(albums.count == 3)
        let url = try #require(await client.requests.first?.url)
        #expect(url.absoluteString.contains("term=Jack%20Johnson"))
    }

    @Test func albumDetailMapsFixture() async throws {
        let client = MockHTTPClient(data: try Fixture.data("lookup"))
        let sut = DefaultAlbumRepository(httpClient: client)

        let detail = try await sut.albumDetail(id: 1440768692)

        #expect(detail.tracks.count == 3)
        let url = try #require(await client.requests.first?.url)
        #expect(url.absoluteString.contains("lookup?id=1440768692"))
    }

    @Test func albumDetailWithEmptyResultIsNotFound() async throws {
        let client = MockHTTPClient(data: Data(#"{"resultCount":0,"results":[]}"#.utf8))
        let sut = DefaultAlbumRepository(httpClient: client)

        await #expect(throws: DomainError.notFound) {
            try await sut.albumDetail(id: 1)
        }
    }

    @Test(arguments: ["not json", "", #"{"foo":1}"#])
    func invalidJSONIsDecodingError(_ body: String) async {
        let sut = DefaultAlbumRepository(httpClient: MockHTTPClient(data: Data(body.utf8)))

        await #expect(throws: DomainError.decoding) {
            try await sut.searchAlbums(query: "x")
        }
    }

    @Test func clientErrorsPropagateUnchanged() async {
        let sut = DefaultAlbumRepository(httpClient: MockHTTPClient { _, _ in throw DomainError.notFound })

        await #expect(throws: DomainError.notFound) {
            try await sut.searchAlbums(query: "x")
        }
    }

    @Test func cancellationPropagatesUnchanged() async {
        let sut = DefaultAlbumRepository(httpClient: MockHTTPClient { _, _ in throw CancellationError() })

        await #expect(throws: CancellationError.self) {
            try await sut.searchAlbums(query: "x")
        }
    }
}
