import Domain
import Testing
@testable import Presentation

@MainActor
struct SearchViewModelTests {
    private func makeSUT(
        results: [Result<[Album], any Error>] = [.success([])]
    ) -> (viewModel: SearchViewModel, useCase: MockSearchAlbumsUseCase, announcer: MockAnnouncer) {
        let useCase = MockSearchAlbumsUseCase(results: results)
        let announcer = MockAnnouncer()
        let viewModel = SearchViewModel(searchAlbums: useCase, debounce: .zero, announcer: announcer)
        return (viewModel, useCase, announcer)
    }

    @Test func startsIdle() {
        let (viewModel, _, _) = makeSUT()
        #expect(viewModel.state == .idle)
    }

    @Test func successfulSearchLoadsAlbums() async {
        let albums = [Album.fixture(id: 1), Album.fixture(id: 2, title: "Fetish")]
        let (viewModel, useCase, _) = makeSUT(results: [.success(albums)])

        viewModel.queryDidChange("rosalia")
        await viewModel.searchTask?.value

        #expect(viewModel.state == .loaded(albums))
        #expect(await useCase.queries == ["rosalia"])
    }

    @Test func emptyResultSetsEmptyState() async {
        let (viewModel, _, _) = makeSUT(results: [.success([])])

        viewModel.queryDidChange("zzzz")
        await viewModel.searchTask?.value

        #expect(viewModel.state == .empty)
    }

    @Test(arguments: [DomainError.network, .decoding, .notFound, .unknown])
    func failureSetsFailedStateWithMessage(error: DomainError) async {
        let (viewModel, _, _) = makeSUT(results: [.failure(error)])

        viewModel.queryDidChange("rosalia")
        await viewModel.searchTask?.value

        guard case .failed(let message) = viewModel.state else {
            Issue.record("Expected .failed, got \(viewModel.state)")
            return
        }
        #expect(!message.isEmpty)
    }

    @Test func nonDomainErrorStillProducesMessage() async {
        struct Unexpected: Error {}
        let (viewModel, _, _) = makeSUT(results: [.failure(Unexpected())])

        viewModel.queryDidChange("rosalia")
        await viewModel.searchTask?.value

        guard case .failed(let message) = viewModel.state else {
            Issue.record("Expected .failed, got \(viewModel.state)")
            return
        }
        #expect(!message.isEmpty)
    }

    @Test(arguments: ["", "   ", "\n"])
    func blankQueryReturnsToIdleWithoutCallingUseCase(blank: String) async {
        let (viewModel, useCase, _) = makeSUT(results: [.success([.fixture()])])

        viewModel.queryDidChange("rosalia")
        await viewModel.searchTask?.value
        #expect(viewModel.state == .loaded([.fixture()]))

        viewModel.queryDidChange(blank)
        await viewModel.searchTask?.value

        #expect(viewModel.state == .idle)
        #expect(await useCase.queries == ["rosalia"])
    }

    @Test func queryIsTrimmedBeforeReachingUseCase() async {
        let (viewModel, useCase, _) = makeSUT(results: [.success([.fixture()])])

        viewModel.queryDidChange("  rosalia \n")
        await viewModel.searchTask?.value

        #expect(await useCase.queries == ["rosalia"])
    }

    @Test func retryRepeatsSearchWithCurrentQuery() async {
        let albums = [Album.fixture()]
        let (viewModel, useCase, _) = makeSUT(results: [.failure(DomainError.network), .success(albums)])

        viewModel.query = "rosalia"
        viewModel.queryDidChange(viewModel.query)
        await viewModel.searchTask?.value
        guard case .failed = viewModel.state else {
            Issue.record("Expected .failed, got \(viewModel.state)")
            return
        }

        viewModel.retry()
        await viewModel.searchTask?.value

        #expect(viewModel.state == .loaded(albums))
        #expect(await useCase.queries == ["rosalia", "rosalia"])
    }

    @Test func cancelledDuringDebounceNeverReachesUseCase() async {
        let useCase = MockSearchAlbumsUseCase(results: [.success([.fixture()])])
        // Debounce enorme: la tarea queda dormida y se cancela, no se espera de verdad.
        let viewModel = SearchViewModel(
            searchAlbums: useCase,
            debounce: .seconds(3600),
            announcer: MockAnnouncer()
        )

        viewModel.queryDidChange("rosalia")
        let sleepingTask = viewModel.searchTask
        viewModel.queryDidChange("")
        await sleepingTask?.value

        #expect(viewModel.state == .idle)
        #expect(await useCase.queries.isEmpty)
    }

    @Test func changingTextDropsPreviousResultsImmediately() async {
        let albums = [Album.fixture(id: 1)]
        let (viewModel, _, _) = makeSUT(results: [.success(albums), .success([])])

        viewModel.queryDidChange("a")
        await viewModel.searchTask?.value
        #expect(viewModel.state == .loaded(albums))

        // Sin esperar a la nueva tarea: los resultados de «a» ya no pueden verse junto a «b».
        viewModel.queryDidChange("b")
        #expect(viewModel.state == .loading)
        await viewModel.searchTask?.value
    }

    @Test func changingTextDropsPreviousErrorImmediately() async {
        let (viewModel, _, _) = makeSUT(results: [.failure(DomainError.network), .success([])])

        viewModel.queryDidChange("a")
        await viewModel.searchTask?.value
        guard case .failed = viewModel.state else {
            Issue.record("Se esperaba .failed")
            return
        }

        viewModel.queryDidChange("b")
        #expect(viewModel.state == .loading)
        await viewModel.searchTask?.value
    }

    // MARK: - Accesibilidad

    @Test(arguments: [1, 25])
    func announcesResultCount(count: Int) async {
        let albums = (1...count).map { Album.fixture(id: $0) }
        let (viewModel, _, announcer) = makeSUT(results: [.success(albums)])

        viewModel.queryDidChange("rosalia")
        await viewModel.searchTask?.value

        #expect(announcer.messages.count == 1)
        #expect(announcer.messages.first?.contains("\(count)") == true)
    }

    @Test func announcesEmptyResults() async {
        let (viewModel, _, announcer) = makeSUT(results: [.success([])])

        viewModel.queryDidChange("zzzz")
        await viewModel.searchTask?.value

        #expect(announcer.messages.count == 1)
    }

    @Test func announcesErrorMessage() async {
        let (viewModel, _, announcer) = makeSUT(results: [.failure(DomainError.network)])

        viewModel.queryDidChange("rosalia")
        await viewModel.searchTask?.value

        guard case .failed(let message) = viewModel.state else {
            Issue.record("Expected .failed, got \(viewModel.state)")
            return
        }
        #expect(announcer.messages == [message])
    }
}
