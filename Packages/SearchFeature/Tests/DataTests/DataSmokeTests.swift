import Testing
@testable import Data

struct DataSmokeTests {
    @Test func moduleLoadsAndSeesDomain() {
        #expect(DataModule.name == "Data")
        #expect(DataModule.domain == "Domain")
    }
}
