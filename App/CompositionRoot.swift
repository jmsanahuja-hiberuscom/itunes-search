import Data
import Domain
import Foundation
import Presentation

/// Único sitio que conoce las tres capas: monta el grafo de dependencias.
@MainActor
struct CompositionRoot {
    static let uiTestMockDataArgument = "-UITestMockData"

    let searchViewModel: SearchViewModel
    private let getAlbumDetail: any GetAlbumDetailUseCase

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        let repository = Self.makeRepository(arguments: arguments)
        getAlbumDetail = DefaultGetAlbumDetailUseCase(repository: repository)
        searchViewModel = SearchViewModel(
            searchAlbums: DefaultSearchAlbumsUseCase(repository: repository),
            announcer: SystemAccessibilityAnnouncer()
        )
    }

    /// `-UITestMockData`: datos fijos en memoria, sin red.
    private static func makeRepository(arguments: [String]) -> any AlbumRepository {
        if arguments.contains(uiTestMockDataArgument) {
            return InMemoryAlbumRepository()
        }
        return DefaultAlbumRepository(httpClient: URLSessionHTTPClient())
    }

    func makeAlbumDetailViewModel(for album: Album) -> AlbumDetailViewModel {
        AlbumDetailViewModel(album: album, getAlbumDetail: getAlbumDetail)
    }
}
