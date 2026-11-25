import XCTest

final class iTunesSearchUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestMockData"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }
}
