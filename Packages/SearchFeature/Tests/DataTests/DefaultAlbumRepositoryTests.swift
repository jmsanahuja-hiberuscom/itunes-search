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

// MARK: - Caché

struct DefaultAlbumRepositoryCacheTests {
    private struct Failure: Error {}

    private func makeSUT(
        clock: TestClock = TestClock(),
        handler: @escaping MockHTTPClient.Handler
    ) -> (DefaultAlbumRepository, MockHTTPClient, TestClock) {
        let client = MockHTTPClient(handler: handler)
        let sut = DefaultAlbumRepository(httpClient: client, now: { clock.now })
        return (sut, client, clock)
    }

    private func response(_ title: String, id: Int = 1) -> Data {
        Data("""
        {"resultCount":1,"results":[{"wrapperType":"collection","collectionId":\(id),\
        "collectionName":"\(title)","artistName":"A"}]}
        """.utf8)
    }

    @Test func firstSearchHitsNetworkOnce() async throws {
        let body = try Fixture.data("search")
        let (sut, client, _) = makeSUT { _, _ in body }

        let albums = try await sut.searchAlbums(query: "jack")

        #expect(albums.count == 3)
        #expect(await client.callCount == 1)
    }

    @Test func secondSearchWithinTTLIsServedFromCache() async throws {
        let body = try Fixture.data("search")
        let (sut, client, clock) = makeSUT { _, _ in body }

        let first = try await sut.searchAlbums(query: "jack")
        clock.advance(by: 179)
        let second = try await sut.searchAlbums(query: "jack")

        #expect(first == second)
        #expect(await client.callCount == 1)
    }

    @Test(arguments: ["JACK", "  jack  ", "Jack\n"])
    func queryCasingAndWhitespaceShareCache(_ variant: String) async throws {
        let body = try Fixture.data("search")
        let (sut, client, _) = makeSUT { _, _ in body }

        _ = try await sut.searchAlbums(query: "jack")
        _ = try await sut.searchAlbums(query: variant)

        #expect(await client.callCount == 1)
    }

    @Test(arguments: ["the  beatles", " The\tBeatles ", "THE BEATLES\n"])
    func innerWhitespaceAndCasingShareCache(_ variant: String) async throws {
        let body = try Fixture.data("search")
        let (sut, client, _) = makeSUT { _, _ in body }

        _ = try await sut.searchAlbums(query: "the beatles")
        _ = try await sut.searchAlbums(query: variant)

        #expect(await client.callCount == 1)
    }

    @Test func differentQueriesHitNetworkSeparately() async throws {
        let body = try Fixture.data("search")
        let (sut, client, _) = makeSUT { _, _ in body }

        _ = try await sut.searchAlbums(query: "jack")
        _ = try await sut.searchAlbums(query: "rosalia")

        #expect(await client.callCount == 2)
    }

    @Test func expiredEntryRefetchesAndStoresNewResult() async throws {
        let (sut, client, clock) = makeSUT { call, _ in
            call == 1 ? response("Old", id: 1) : response("New", id: 2)
        }

        let first = try await sut.searchAlbums(query: "x")
        clock.advance(by: 180)
        let second = try await sut.searchAlbums(query: "x")
        let third = try await sut.searchAlbums(query: "x")

        #expect(first.map(\.title) == ["Old"])
        #expect(second.map(\.title) == ["New"])
        #expect(third.map(\.title) == ["New"])
        #expect(await client.callCount == 2)
    }

    @Test func networkErrorIsNotCached() async throws {
        let (sut, client, _) = makeSUT { call, _ in
            if call == 1 { throw Failure() }
            return response("Ok")
        }

        await #expect(throws: Failure.self) { try await sut.searchAlbums(query: "x") }
        let albums = try await sut.searchAlbums(query: "x")

        #expect(albums.count == 1)
        #expect(await client.callCount == 2)
    }

    @Test func cancelledSearchIsNotCached() async throws {
        let (sut, client, _) = makeSUT { call, _ in
            if call == 1 { throw CancellationError() }
            return response("Ok")
        }

        await #expect(throws: CancellationError.self) { try await sut.searchAlbums(query: "x") }
        _ = try await sut.searchAlbums(query: "x")

        #expect(await client.callCount == 2)
    }

    @Test func responseArrivingAfterCancellationIsNotCached() async throws {
        let body = response("Ok")
        let (sut, client, _) = makeSUT { _, _ in body }

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.searchAlbums(query: "x")
        }
        await #expect(throws: CancellationError.self) { try await task.value }
        _ = try await sut.searchAlbums(query: "x")

        #expect(await client.callCount == 2)
    }
}
