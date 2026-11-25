import Testing
@testable import Presentation

@MainActor
struct PresentationSmokeTests {
    @Test func moduleLoadsAndSeesDomain() {
        #expect(PresentationModule.name == "Presentation")
        #expect(PresentationModule.domain == "Domain")
    }
}
