import Domain
import Testing
@testable import Presentation

struct UserMessageTests {
    @Test(arguments: [DomainError.network, .decoding, .notFound, .unknown])
    func everyDomainErrorHasAMessage(error: DomainError) {
        #expect(!UserMessage.message(for: error).isEmpty)
    }

    @Test func eachDomainErrorHasItsOwnMessageExceptUnknownFallback() {
        let messages = [DomainError.network, .decoding, .notFound, .unknown].map(UserMessage.message(for:))
        #expect(Set(messages).count == messages.count)
    }

    @Test func foreignErrorFallsBackToUnknownMessage() {
        struct Foreign: Error {}
        #expect(UserMessage.message(for: Foreign()) == UserMessage.message(for: DomainError.unknown))
    }
}
