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
        let app = XCUIApplication()
        app.launch()

        try app.performAccessibilityAudit()
    }

    @MainActor
    func testElDashboardPasaLaAuditoria() throws {
        let app = XCUIApplication()
        app.launch()

        try startUsingTheApp(app)

        XCTAssertTrue(
            app.buttons["Registrar"].waitForExistence(timeout: 5),
            "Se esperaba llegar al dashboard, con su acción de registrar a la vista"
        )

        try app.performAccessibilityAudit()
    }

    @MainActor
    func testElRegistroRapidoPasaLaAuditoria() throws {
        let app = XCUIApplication()
        app.launch()

        try startUsingTheApp(app)

        let record = app.buttons["Registrar"]
        XCTAssertTrue(record.waitForExistence(timeout: 5))
        record.tap()

        XCTAssertTrue(app.staticTexts["Peso"].waitForExistence(timeout: 5))

        try app.performAccessibilityAudit()
    }

    /// Deja la app en el dashboard: si aparece la bienvenida, crea un compañero;
    /// si ya había uno de una corrida anterior, sigue de largo.
    @MainActor
    private func startUsingTheApp(_ app: XCUIApplication) throws {
        let start = app.buttons["Empezar"]

        guard start.waitForExistence(timeout: 5) else { return }

        start.tap()

        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Luli")

        app.buttons["Empezar"].firstMatch.tap()
    }
}
