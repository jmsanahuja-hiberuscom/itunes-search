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
        let repository: any AlbumRepository
        if arguments.contains(Self.uiTestMockDataArgument) {
            repository = InMemoryAlbumRepository()
        } else {
            repository = DefaultAlbumRepository(httpClient: URLSessionHTTPClient())
        }
        getAlbumDetail = DefaultGetAlbumDetailUseCase(repository: repository)
        searchViewModel = SearchViewModel(
            searchAlbums: DefaultSearchAlbumsUseCase(repository: repository),
            announcer: SystemAccessibilityAnnouncer()
        )
    }

    func makeAlbumDetailViewModel(for album: Album) -> AlbumDetailViewModel {
        AlbumDetailViewModel(album: album, getAlbumDetail: getAlbumDetail)
    }
}
