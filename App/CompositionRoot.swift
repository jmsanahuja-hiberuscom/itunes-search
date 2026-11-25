import Data
import Domain
import Foundation
import Presentation

/// Único sitio que conoce las tres capas: monta el grafo de dependencias.
@MainActor
struct CompositionRoot {
    static let uiTestMockDataArgument = "-UITestMockData"
    static let uiTestMockErrorArgument = "-UITestMockError"

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

    /// - `-UITestMockData`: datos fijos en memoria.
    /// - `-UITestMockError`: la búsqueda falla.
    /// - Ambos: se puede buscar, pero el detalle falla.
    private static func makeRepository(arguments: [String]) -> any AlbumRepository {
        let mockData = arguments.contains(uiTestMockDataArgument)
        let mockError = arguments.contains(uiTestMockErrorArgument)
        switch (mockData, mockError) {
        case (true, true): return FailingAlbumRepository(searchSource: InMemoryAlbumRepository())
        case (false, true): return FailingAlbumRepository()
        case (true, false): return InMemoryAlbumRepository()
        case (false, false): return DefaultAlbumRepository(httpClient: URLSessionHTTPClient())
        }
    }

    func makeAlbumDetailViewModel(for album: Album) -> AlbumDetailViewModel {
        AlbumDetailViewModel(album: album, getAlbumDetail: getAlbumDetail)
    }
}
