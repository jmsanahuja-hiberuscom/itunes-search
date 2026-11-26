import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class SearchViewModel {
    /// Texto del campo de búsqueda. La vista lo enlaza y llama a `queryDidChange(_:)` desde `.onChange`.
    public var query = ""
    public private(set) var state: ViewState<[Album]> = .idle

    /// Tarea de la búsqueda en curso. Lectura `internal` para que los tests
    /// puedan esperar su final con `await searchTask?.value`, sin sleeps.
    private(set) var searchTask: Task<Void, Never>?

    private let searchAlbums: any SearchAlbumsUseCase
    private let debounce: Duration
    private let announcer: any AccessibilityAnnouncer

    public init(
        searchAlbums: any SearchAlbumsUseCase,
        debounce: Duration = .milliseconds(300),
        announcer: any AccessibilityAnnouncer
    ) {
        self.searchAlbums = searchAlbums
        self.debounce = debounce
        self.announcer = announcer
    }

    /// Cancela la búsqueda anterior y lanza otra para `newQuery`.
    /// Query vacía → vuelve a `.idle` sin tocar el use case.
    public func queryDidChange(_ newQuery: String) {
        searchTask?.cancel()
        let trimmed = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchTask = nil
            state = .idle
            return
        }
        // Lo que haya en pantalla (resultados, vacío o error) es de un texto anterior:
        // se descarta ya, sin esperar al debounce.
        state = .loading
        searchTask = Task { [weak self] in
            await self?.performSearch(query: trimmed)
        }
    }

    /// Repite la búsqueda con la query actual (botón «Reintentar»).
    public func retry() {
        queryDidChange(query)
    }

    private func performSearch(query: String) async {
        do {
            if debounce > .zero {
                try await Task.sleep(for: debounce)
            }
            let albums = try await searchAlbums.execute(query: query)
            // Una búsqueda cancelada nunca puede pintar sus resultados,
            // aunque el use case los haya devuelto igualmente.
            guard !Task.isCancelled else { return }
            if albums.isEmpty {
                state = .empty
                announcer.announce(String(localized: "search.announcement.empty", bundle: .module))
            } else {
                state = .loaded(albums)
                announcer.announce(Self.resultsAnnouncement(count: albums.count))
            }
        } catch is CancellationError {
            // Cancelar no es un error para el usuario.
        } catch {
            guard !Task.isCancelled else { return }
            let message = UserMessage.message(for: error)
            state = .failed(message: message)
            announcer.announce(message)
        }
    }

    private static func resultsAnnouncement(count: Int) -> String {
        // Claves literales (una por categoría plural) para que Xcode las extraiga al catálogo.
        let format = count == 1
            ? String(localized: "search.announcement.results.one", bundle: .module)
            : String(localized: "search.announcement.results.other", bundle: .module)
        return String(format: format, count)
    }
}
