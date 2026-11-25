import Domain
import Foundation

public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw Self.map(error)
        }
        guard let http = response as? HTTPURLResponse else {
            DataLogger.network.error("Non-HTTP response for \(request.url?.absoluteString ?? "-", privacy: .public)")
            throw DomainError.network
        }
        try Self.validate(statusCode: http.statusCode)
        return (data, http)
    }

    /// 2xx → OK, 404 → `.notFound`, resto → `.network`.
    static func validate(statusCode: Int) throws {
        switch statusCode {
        case 200...299: return
        case 404:
            DataLogger.network.error("HTTP 404")
            throw DomainError.notFound
        default:
            DataLogger.network.error("HTTP \(statusCode, privacy: .public)")
            throw DomainError.network
        }
    }

    /// `URLError.cancelled` es una cancelación, no un error de red.
    static func map(_ error: Error) -> Error {
        if error is CancellationError { return error }
        if let urlError = error as? URLError {
            if urlError.code == .cancelled { return CancellationError() }
            DataLogger.network.error("Transport error: \(urlError.code.rawValue, privacy: .public)")
            return DomainError.network
        }
        DataLogger.network.error("Unexpected error: \(String(describing: error), privacy: .public)")
        return DomainError.network
    }
}
