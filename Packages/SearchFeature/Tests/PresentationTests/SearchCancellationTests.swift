import Domain
import Testing
@testable import Presentation

/// Garantía central de la búsqueda: nunca se pintan resultados de una query anterior.
/// Todo es determinista: el orden de las respuestas lo decide el test, no el reloj.
@MainActor
struct SearchCancellationTests {
    private func makeSUT(
        cancellationBehavior: ControllableSearchUseCase.CancellationBehavior
    ) -> (viewModel: SearchViewModel, useCase: ControllableSearchUseCase) {
        let useCase = ControllableSearchUseCase(cancellationBehavior: cancellationBehavior)
        let viewModel = SearchViewModel(searchAlbums: useCase, debounce: .zero, announcer: MockAnnouncer())
        return (viewModel, useCase)
    }

    @Test func staleResultsAreNeverShownEvenIfUseCaseIgnoresCancellation() async {
        let (viewModel, useCase) = makeSUT(cancellationBehavior: .ignore)
        let albumsA = [Album.fixture(id: 1, title: "A")]
        let albumsB = [Album.fixture(id: 2, title: "B")]

        viewModel.queryDidChange("a")
        let taskA = viewModel.searchTask
        await useCase.waitForCall(query: "a")

        viewModel.queryDidChange("b")
        await useCase.waitForCall(query: "b")

        // Primero responde «b» (la vigente).
        #expect(await useCase.resume(query: "b", with: albumsB))
        await viewModel.searchTask?.value
        #expect(viewModel.state == .loaded(albumsB))

        // Después responde «a», ya obsoleta: el estado no debe cambiar.
        #expect(await useCase.resume(query: "a", with: albumsA))
        await taskA?.value
        #expect(viewModel.state == .loaded(albumsB))

        // La tarea de «a» sí recibió la cancelación.
        #expect(await useCase.wasCancelledWhenResumed(query: "a") == true)
        #expect(await useCase.wasCancelledWhenResumed(query: "b") == false)
    }

    @Test func cancelledSearchDoesNotProduceFailedState() async {
        let (viewModel, useCase) = makeSUT(cancellationBehavior: .throwCancellationError)
        let albumsB = [Album.fixture(id: 2, title: "B")]

        viewModel.queryDidChange("a")
        let taskA = viewModel.searchTask
        await useCase.waitForCall(query: "a")

        viewModel.queryDidChange("b")
        await useCase.waitForCall(query: "b")

        // «a» termina por cancelación (el mock reanuda con CancellationError):
        // no deja error ni resultados; el estado sigue siendo el de «b» cargando.
        await taskA?.value
        #expect(viewModel.state == .loading)

        #expect(await useCase.resume(query: "b", with: albumsB))
        await viewModel.searchTask?.value
        #expect(viewModel.state == .loaded(albumsB))
    }

    @Test func clearingQueryWhileSearchIsInFlightKeepsIdle() async {
        let (viewModel, useCase) = makeSUT(cancellationBehavior: .ignore)

        viewModel.queryDidChange("a")
        let taskA = viewModel.searchTask
        await useCase.waitForCall(query: "a")

        viewModel.queryDidChange("")
        #expect(viewModel.state == .idle)

        #expect(await useCase.resume(query: "a", with: [.fixture()]))
        await taskA?.value

        #expect(viewModel.state == .idle)
    }
}
