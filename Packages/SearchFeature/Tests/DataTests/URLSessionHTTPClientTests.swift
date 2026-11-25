import Domain
import Foundation
import Testing
@testable import Data

struct URLSessionHTTPClientTests {
    @Test(arguments: [200, 201, 204, 299])
    func successStatusCodesPass(_ code: Int) throws {
        try URLSessionHTTPClient.validate(statusCode: code)
    }

    @Test func notFoundMapsToNotFound() {
        #expect(throws: DomainError.notFound) {
            try URLSessionHTTPClient.validate(statusCode: 404)
        }
    }

    @Test(arguments: [301, 400, 403, 429, 500, 503])
    func otherStatusCodesMapToNetwork(_ code: Int) {
        #expect(throws: DomainError.network) {
            try URLSessionHTTPClient.validate(statusCode: code)
        }
    }

    @Test func urlErrorCancelledBecomesCancellationError() {
        let mapped = URLSessionHTTPClient.map(URLError(.cancelled))
        #expect(mapped is CancellationError)
    }

    @Test func otherURLErrorsBecomeNetwork() {
        let mapped = URLSessionHTTPClient.map(URLError(.notConnectedToInternet))
        #expect(mapped as? DomainError == .network)
    }

    @Test func cancellationErrorPassesThrough() {
        #expect(URLSessionHTTPClient.map(CancellationError()) is CancellationError)
    }
}
