import XCTest

final class iTunesSearchUITests: XCTestCase {
    private static let mockData = "-UITestMockData"
    private static let largeText = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]

    private let timeout: TimeInterval = 10

    override func setUp() {
        continueAfterFailure = false
    }

    // MARK: - Flujo feliz

    @MainActor
    func testSearchOpenDetailAndGoBack() {
        let app = launch()
        searchAndOpenDetail(in: app)
        goBackToSearch(in: app)
    }

    @MainActor
    func testSearchOpenDetailAndGoBackWithLargeDynamicType() {
        let app = launch(extraArguments: Self.largeText)
        searchAndOpenDetail(in: app)
        goBackToSearch(in: app)
    }

    // MARK: - iPad (ancho regular)

    @MainActor
    func testDetailUsesTwoColumnsOnIPad() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "Solo iPad")
        let app = launch()
        searchAndOpenDetail(in: app)

        let hero = app.descendants(matching: .any)["album-hero"]
        XCTAssertTrue(hero.waitForExistence(timeout: timeout))
        let openButton = app.buttons["open-apple-music"]
        // Dos columnas: la cabecera queda a la izquierda del contenido, no encima.
        XCTAssertLessThanOrEqual(hero.frame.maxX, openButton.frame.minX)
    }

    @MainActor
    func testSearchFieldIsPinnedUnderTitleOnIPad() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "Solo iPad")
        let app = launch()

        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: timeout))
        // Fijado bajo el título ocupa el ancho; la pastilla de la esquina ocupa una parte pequeña.
        XCTAssertGreaterThan(field.frame.width, app.frame.width / 2)
    }

    // MARK: - Auditoría de accesibilidad

    @MainActor
    func testAccessibilityAuditOnSearch() throws {
        let app = launch()
        search("Rosalía", submit: true, in: app)
        XCTAssertTrue(app.buttons["album-row-1"].waitForExistence(timeout: timeout))
        try app.performAccessibilityAudit(for: .all, handleKnownIssues)
    }

    @MainActor
    func testAccessibilityAuditOnDetail() throws {
        let app = launch()
        searchAndOpenDetail(in: app)
        try app.performAccessibilityAudit(for: .all, handleKnownIssues)
    }

    // MARK: - Helpers

    @MainActor
    private func launch(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [Self.mockData] + extraArguments
        app.launch()
        return app
    }

    @MainActor
    private func search(_ text: String, submit: Bool = false, in app: XCUIApplication) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: timeout))
        field.tap()
        // `submit` pulsa Intro para cerrar el teclado: sus teclas las audita el sistema sin descripción.
        field.typeText(submit ? text + "\n" : text)
    }

    @MainActor
    private func searchAndOpenDetail(in app: XCUIApplication) {
        search("Rosalía", in: app)
        let row = app.buttons["album-row-1"]
        XCTAssertTrue(row.waitForExistence(timeout: timeout))
        row.tap()
        XCTAssertTrue(app.staticTexts["Track 1"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["open-apple-music"].exists)
    }

    @MainActor
    private func goBackToSearch(in app: XCUIApplication) {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["album-row-1"].waitForExistence(timeout: timeout))
    }

    /// Devuelve `true` para ignorar un aviso. Solo se ignoran falsos positivos del sistema,
    /// de uno en uno y con su motivo; cualquier otro aviso hace fallar el test.
    private func handleKnownIssues(_ issue: XCUIAccessibilityAuditIssue) -> Bool {
        // El botón de borrar texto del campo de búsqueda es un control del sistema (UISearchBar)
        // de ~19 pt que la app no controla ni puede ampliar.
        if issue.auditType == .hitRegion, isSearchFieldClearButton(issue.element) {
            return true
        }

        // Con el color semántico `.secondary` sobre la tarjeta, el auditor da "Contrast nearly passed":
        // es la heurística del sistema sobre colores del sistema, no un color propio de la app.
        // Solo se ignora ese veredicto límite; un "Contrast failed" seguiría haciendo fallar el test.
        if issue.auditType == .contrast, issue.compactDescription == "Contrast nearly passed" {
            return true
        }

        return false
    }

    private func isSearchFieldClearButton(_ element: XCUIElement?) -> Bool {
        guard let element else { return false }
        return MainActor.assumeIsolated {
            element.elementType == .button && ["Borrar texto", "Clear text"].contains(element.label)
        }
    }
}
