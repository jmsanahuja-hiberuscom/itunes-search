import Foundation
import Testing
@testable import Data

struct EndpointTests {
    @Test func searchBuildsExpectedURL() throws {
        let url = try #require(Endpoint.search(term: "radiohead").url)
        #expect(url.absoluteString ==
            "https://itunes.apple.com/search?term=radiohead&media=music&entity=album&limit=25")
    }

    @Test func searchEncodesSpacesAndAccents() throws {
        let url = try #require(Endpoint.search(term: "Rosalía Motomami").url)
        #expect(url.absoluteString.contains("term=Rosal%C3%ADa%20Motomami"))
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(items.first { $0.name == "term" }?.value == "Rosalía Motomami")
    }

    @Test func searchEncodesReservedCharacters() throws {
        let url = try #require(Endpoint.search(term: "a&b+c").url)
        #expect(url.absoluteString.contains("term=a%26b%2Bc"))
    }

    @Test func lookupBuildsExpectedURL() throws {
        let url = try #require(Endpoint.lookup(id: 1440768692).url)
        #expect(url.absoluteString == "https://itunes.apple.com/lookup?id=1440768692&entity=song")
    }
}
