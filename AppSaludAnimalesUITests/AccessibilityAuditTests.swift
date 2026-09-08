import XCTest

/// Auditoría de accesibilidad automática.
///
/// Es la misma que ofrece el Accessibility Inspector de Xcode, pero corriendo
/// como una prueba más: detecta elementos sin etiqueta, contraste insuficiente,
/// áreas de toque chicas y texto que se corta.
///
/// No reemplaza probar con VoiceOver —eso está en docs/accesibilidad.md— pero
/// encuentra sola lo que es mecánico, en cada vuelta y sin acordarse.
final class AccessibilityAuditTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testLaPrimeraPantallaPasaLaAuditoria() throws {
        let app = launchApp()

        try app.performAccessibilityAudit()
    }

    @MainActor
    func testElDashboardPasaLaAuditoria() throws {
        let app = launchApp()

        try startUsingTheApp(app)

        XCTAssertTrue(
            app.buttons["Registrar"].waitForExistence(timeout: 5),
            "Se esperaba llegar al dashboard, con su acción de registrar a la vista"
        )

        try app.performAccessibilityAudit()
    }

    @MainActor
    func testElRegistroRapidoPasaLaAuditoria() throws {
        let app = launchApp()

        try startUsingTheApp(app)

        let record = app.buttons["Registrar"]
        XCTAssertTrue(record.waitForExistence(timeout: 5))
        record.tap()

        XCTAssertTrue(app.staticTexts["Peso"].waitForExistence(timeout: 5))

        try app.performAccessibilityAudit()
    }

    /// Arranca la app con datos limpios, para que el recorrido sea siempre el
    /// mismo y una falla signifique siempre lo mismo.
    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-uiTesting")
        app.launch()
        return app
    }

    /// Deja la app en el dashboard creando un compañero desde la bienvenida.
    @MainActor
    private func startUsingTheApp(_ app: XCUIApplication) throws {
        let start = app.buttons["Empezar"]
        XCTAssertTrue(start.waitForExistence(timeout: 10), "Se esperaba la bienvenida")
        start.tap()

        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Luli")

        app.buttons["Empezar"].firstMatch.tap()
    }
}
