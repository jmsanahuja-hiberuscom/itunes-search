import Domain
import Foundation

public struct DefaultAlbumRepository: AlbumRepository {
    private let httpClient: any HTTPClient

    public init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    public func searchAlbums(query: String) async throws -> [Album] {
        try await fetch(.search(term: query)).toAlbums()
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
