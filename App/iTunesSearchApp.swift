import Presentation
import SwiftUI

@main
struct iTunesSearchApp: App {
    @State private var root: CompositionRoot

    init() {
        // Caché compartida para que los artworks no se descarguen de nuevo.
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        )
        _root = State(initialValue: CompositionRoot())
    }

    var body: some Scene {
        WindowGroup {
            SearchView(
                viewModel: root.searchViewModel,
                makeDetailViewModel: root.makeAlbumDetailViewModel(for:)
            )
        }
    }
}
