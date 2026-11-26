import Domain
import Foundation

public struct DefaultAlbumRepository: AlbumRepository {
    private let httpClient: any HTTPClient
    private let searchCache: InMemoryCache<String, [Album]>

    public init(
        httpClient: any HTTPClient,
        cacheTTL: TimeInterval = 180,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.httpClient = httpClient
        self.searchCache = InMemoryCache(ttl: cacheTTL, now: now)
    }

    public func searchAlbums(query: String) async throws -> [Album] {
        // La clave se normaliza; a la API se le envía el término tal cual.
        let key = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let cached = await searchCache.value(for: key) {
            return cached
        }
        let albums = try await fetch(.search(term: query)).toAlbums()
        // Una respuesta que llega tras cancelar no se devuelve ni se cachea.
        try Task.checkCancellation()
        await searchCache.insert(albums, for: key)
        return albums
    }

    public func albumDetail(id: Int) async throws -> AlbumDetail {
        guard let detail = try await fetch(.lookup(id: id)).toAlbumDetail() else {
            throw DomainError.notFound
        }
        return detail
    }

    private func fetch(_ endpoint: Endpoint) async throws -> ResponseDTO {
        guard let request = endpoint.request else { throw DomainError.unknown }
        let (data, _) = try await httpClient.data(for: request)
        do {
            return try JSONDecoder().decode(ResponseDTO.self, from: data)
        } catch {
            DataLogger.network.error("Decoding failed: \(String(describing: error), privacy: .public)")
            throw DomainError.decoding
        }
    }
}
