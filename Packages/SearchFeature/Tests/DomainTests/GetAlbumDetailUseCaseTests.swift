import Testing
@testable import Domain

struct GetAlbumDetailUseCaseTests {
    @Test func delegatesWithCorrectIDAndReturnsDetail() async throws {
        let detail = AlbumDetail(
            album: .fixture(id: 42),
            tracks: [Track(id: 1, number: 1, name: "SAOKO", duration: .seconds(137))]
        )
        let repository = MockAlbumRepository(detailResult: .success(detail))
        let sut = DefaultGetAlbumDetailUseCase(repository: repository)

        let result = try await sut.execute(id: 42)

        #expect(result == detail)
        #expect(await repository.detailIDs == [42])
    }

    @Test func repositoryErrorIsPropagated() async {
        let repository = MockAlbumRepository(detailResult: .failure(DomainError.notFound))
        let sut = DefaultGetAlbumDetailUseCase(repository: repository)

        await #expect(throws: DomainError.notFound) {
            try await sut.execute(id: 7)
        }
    }
}
