import Domain
import Testing
@testable import Presentation

@MainActor
struct AlbumDetailViewModelTests {
    private let album = Album.fixture(id: 42)

    private func makeSUT(
        results: [Result<AlbumDetail, any Error>]
    ) -> (viewModel: AlbumDetailViewModel, useCase: MockGetAlbumDetailUseCase) {
        let useCase = MockGetAlbumDetailUseCase(results: results)
        return (AlbumDetailViewModel(album: album, getAlbumDetail: useCase), useCase)
    }

    @Test func startsIdle() {
        let (viewModel, _) = makeSUT(results: [.success(.fixture())])
        #expect(viewModel.state == .idle)
    }

    @Test func loadSetsLoadedStateForAlbumID() async {
        let detail = AlbumDetail.fixture(album: album)
        let (viewModel, useCase) = makeSUT(results: [.success(detail)])

        await viewModel.load()

        #expect(viewModel.state == .loaded(detail))
        #expect(await useCase.ids == [42])
    }

    @Test(arguments: [DomainError.network, .decoding, .notFound, .unknown])
    func loadFailureSetsFailedStateWithMessage(error: DomainError) async {
        let (viewModel, _) = makeSUT(results: [.failure(error)])

        await viewModel.load()

        guard case .failed(let message) = viewModel.state else {
            Issue.record("Expected .failed, got \(viewModel.state)")
            return
        }
        #expect(!message.isEmpty)
    }

    @Test func retryCallsUseCaseAgainAndRecovers() async {
        let detail = AlbumDetail.fixture(album: album)
        let (viewModel, useCase) = makeSUT(results: [.failure(DomainError.network), .success(detail)])

        await viewModel.load()
        guard case .failed = viewModel.state else {
            Issue.record("Expected .failed, got \(viewModel.state)")
            return
        }

        await viewModel.retry()

        #expect(viewModel.state == .loaded(detail))
        #expect(await useCase.ids == [42, 42])
    }

    @Test func loadDoesNotRefetchOnceLoaded() async {
        let (viewModel, useCase) = makeSUT(results: [.success(.fixture(album: album))])

        await viewModel.load()
        await viewModel.load()

        #expect(await useCase.ids == [42])
    }

    @Test func loadRefetchesAfterFailure() async {
        let detail = AlbumDetail.fixture(album: album)
        let (viewModel, useCase) = makeSUT(results: [.failure(DomainError.network), .success(detail)])

        await viewModel.load()
        await viewModel.load()

        #expect(viewModel.state == .loaded(detail))
        #expect(await useCase.ids == [42, 42])
    }

    @Test func cancelledLoadDoesNotProduceFailedState() async {
        let (viewModel, _) = makeSUT(results: [.failure(CancellationError())])

        await viewModel.load()

        #expect(viewModel.state == .idle)
    }
}
