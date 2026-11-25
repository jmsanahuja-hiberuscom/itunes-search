import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class AlbumDetailViewModel {
    /// Álbum seleccionado en la búsqueda; permite pintar la cabecera mientras carga el detalle.
    public let album: Album
    public private(set) var state: ViewState<AlbumDetail> = .idle

    private let getAlbumDetail: any GetAlbumDetailUseCase

    public init(album: Album, getAlbumDetail: any GetAlbumDetailUseCase) {
        self.album = album
        self.getAlbumDetail = getAlbumDetail
    }

    /// Carga el detalle si aún no está cargado. Pensado para `.task` de la vista.
    public func load() async {
        if case .loaded = state { return }
        await fetch()
    }

    /// Vuelve a pedir el detalle (botón «Reintentar»).
    public func retry() async {
        await fetch()
    }

    private func fetch() async {
        state = .loading
        do {
            let detail = try await getAlbumDetail.execute(id: album.id)
            guard !Task.isCancelled else {
                state = .idle
                return
            }
            state = .loaded(detail)
        } catch is CancellationError {
            // La vista desapareció: se vuelve a cargar cuando reaparezca.
            state = .idle
        } catch {
            guard !Task.isCancelled else {
                state = .idle
                return
            }
            state = .failed(message: UserMessage.message(for: error))
        }
    }
}
