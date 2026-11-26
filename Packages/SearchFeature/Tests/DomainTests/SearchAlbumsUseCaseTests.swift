import Testing
@testable import Domain

struct SearchAlbumsUseCaseTests {
    @Test func returnsAlbumsFromRepository() async throws {
        let albums = [Album.fixture(id: 1), Album.fixture(id: 2, title: "El mal querer")]
        let repository = MockAlbumRepository(searchResult: .success(albums))
        let sut = DefaultSearchAlbumsUseCase(repository: repository)

        let result = try await sut.execute(query: "rosalía")

        #expect(result == albums)
    }

    @Test(arguments: ["", "   ", "\n"])
    func blankQueryReturnsEmptyWithoutCallingRepository(query: String) async throws {
        let repository = MockAlbumRepository(searchResult: .success([.fixture()]))
        let sut = DefaultSearchAlbumsUseCase(repository: repository)

        let result = try await sut.execute(query: query)

        #expect(result.isEmpty)
        #expect(await repository.searchQueries.isEmpty)
    }

    @Test func queryReachesRepositoryTrimmed() async throws {
        let repository = MockAlbumRepository()
        let sut = DefaultSearchAlbumsUseCase(repository: repository)

        _ = try await sut.execute(query: "  Radiohead \n")

        #expect(await repository.searchQueries == ["Radiohead"])
    }

    @Test func repositoryErrorIsPropagated() async {
        let repository = MockAlbumRepository(searchResult: .failure(DomainError.network))
        let sut = DefaultSearchAlbumsUseCase(repository: repository)

        await #expect(throws: DomainError.network) {
            try await sut.execute(query: "daft punk")
        }
    }

    @Test func cancellationErrorIsPropagatedUntransformed() async {
        let repository = MockAlbumRepository(searchResult: .failure(CancellationError()))
        let sut = DefaultSearchAlbumsUseCase(repository: repository)

        await #expect(throws: CancellationError.self) {
            try await sut.execute(query: "daft punk")
        }
    }
}
