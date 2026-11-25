import Foundation
@testable import Data

/// Mock que registra las peticiones y responde con un handler por llamada.
actor MockHTTPClient: HTTPClient {
    typealias Handler = @Sendable (_ callNumber: Int, _ request: URLRequest) throws -> Data

    private let handler: Handler
    private(set) var requests: [URLRequest] = []

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    init(data: Data) {
        self.handler = { _, _ in data }
    }

    var callCount: Int { requests.count }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let data = try handler(requests.count, request)
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        else { throw URLError(.badURL) }
        return (data, response)
    }
}
