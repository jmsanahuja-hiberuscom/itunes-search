import Foundation

struct Endpoint: Equatable, Sendable {
    static let host = "itunes.apple.com"
    static let searchLimit = 25

    let path: String
    let queryItems: [URLQueryItem]

    static func search(term: String, limit: Int = searchLimit) -> Endpoint {
        Endpoint(path: "/search", queryItems: [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "album"),
            URLQueryItem(name: "limit", value: String(limit)),
        ])
    }

    static func lookup(id: Int) -> Endpoint {
        Endpoint(path: "/lookup", queryItems: [
            URLQueryItem(name: "id", value: String(id)),
            URLQueryItem(name: "entity", value: "song"),
        ])
    }

    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Self.host
        components.path = path
        components.queryItems = queryItems
        // URLComponents deja "+" sin escapar y el servidor lo leería como espacio.
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
        return components.url
    }

    var request: URLRequest? {
        url.map { URLRequest(url: $0) }
    }
}
