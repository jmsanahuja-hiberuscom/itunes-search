import Domain
import SwiftUI

/// Pantalla de búsqueda. Sin lógica: pinta `viewModel.state` y delega los eventos.
public struct SearchView: View {
    @Bindable private var viewModel: SearchViewModel
    private let makeDetailViewModel: @MainActor (Album) -> AlbumDetailViewModel

    private static let suggestions = ["Rosalía", "Radiohead", "Daft Punk"]

    public init(
        viewModel: SearchViewModel,
        makeDetailViewModel: @escaping @MainActor (Album) -> AlbumDetailViewModel
    ) {
        self.viewModel = viewModel
        self.makeDetailViewModel = makeDetailViewModel
    }

    public var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: Metrics.readingWidth)
                .frame(maxWidth: .infinity)
                .motionSafeAnimation(value: viewModel.state)
                .navigationTitle(Text("search.title", bundle: .module))
                .searchable(text: $viewModel.query, prompt: Text("search.prompt", bundle: .module))
                .onChange(of: viewModel.query) { _, newValue in
                    viewModel.queryDidChange(newValue)
                }
                .navigationDestination(for: Album.self) { album in
                    AlbumDetailView(viewModel: makeDetailViewModel(album))
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            welcome.transition(.opacity)
        case .loading:
            ScrollView { SkeletonList() }
                .scrollDisabled(true)
                .transition(.opacity)
        case .loaded(let albums):
            results(albums).transition(.opacity)
        case .empty:
            ContentUnavailableView.search(text: viewModel.query).transition(.opacity)
        case .failed(let message):
            ErrorStateView(message: message) { viewModel.retry() }.transition(.opacity)
        }
    }

    private var welcome: some View {
        EmptyStateView(
            title: "search.welcome.title",
            systemImage: "music.note.list",
            message: "search.welcome.message"
        ) {
            FlowLayout {
                ForEach(Self.suggestions, id: \.self) { suggestion in
                    Button(suggestion) { viewModel.query = suggestion }
                        .buttonStyle(.chip)
                        .accessibilityHint(Text("search.suggestion.hint", bundle: .module))
                        .accessibilityIdentifier("suggestion-\(suggestion)")
                }
            }
        }
    }

    private func results(_ albums: [Album]) -> some View {
        List(albums) { album in
            NavigationLink(value: album) {
                AlbumRow(album: album)
            }
            .accessibilityIdentifier("album-row-\(album.id)")
        }
        .listStyle(.plain)
    }
}

#if DEBUG
@MainActor
private func previewSearch(
    query: String = "",
    useCase: some SearchAlbumsUseCase = PreviewSearchAlbums()
) -> some View {
    let viewModel = SearchViewModel(
        searchAlbums: useCase,
        debounce: .zero,
        announcer: SystemAccessibilityAnnouncer()
    )
    viewModel.query = query
    viewModel.queryDidChange(query)
    return SearchView(viewModel: viewModel) { album in
        AlbumDetailViewModel(album: album, getAlbumDetail: PreviewGetAlbumDetail())
    }
}

#Preview("Inicio · iPhone SE (3.ª gen)", traits: .fixedLayout(width: 375, height: 667)) { previewSearch() }
#Preview("Resultados · iPhone 16", traits: .fixedLayout(width: 393, height: 852)) { previewSearch(query: "bad") }
#Preview("Resultados · iPhone 16 Pro Max", traits: .fixedLayout(width: 440, height: 956)) { previewSearch(query: "bad") }
#Preview("Resultados · oscuro") { previewSearch(query: "bad").preferredColorScheme(.dark) }
#Preview("Resultados · accesibilidad 3") {
    previewSearch(query: "bad").environment(\.dynamicTypeSize, .accessibility3)
}
#Preview("Resultados · horizontal", traits: .landscapeLeft) { previewSearch(query: "bad") }
#Preview("Cargando") { previewSearch(query: "bad", useCase: PreviewNeverFinishes()) }
#Preview("Vacío") { previewSearch(query: "zzz", useCase: PreviewSearchAlbums(result: .success([]))) }
#Preview("Error") {
    previewSearch(query: "bad", useCase: PreviewSearchAlbums(result: .failure(.network)))
}
#endif
