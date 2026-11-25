import Testing
@testable import Domain

struct DomainSmokeTests {
    @Test func moduleLoads() {
        #expect(DomainModule.name == "Domain")
    }
}
