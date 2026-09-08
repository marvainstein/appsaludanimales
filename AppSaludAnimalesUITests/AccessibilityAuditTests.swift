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

        try app.performAccessibilityAudit()
    }

    @MainActor
    func testElRegistroRapidoPasaLaAuditoria() throws {
        let app = launchApp()
        try startUsingTheApp(app)

        app.buttons["dashboard.record"].tap()

        XCTAssertTrue(
            app.buttons["quickRecord.weight"].waitForExistence(timeout: 5),
            "Se esperaban las opciones del registro rápido"
        )

        try app.performAccessibilityAudit()
    }

    // MARK: - Recorrido

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
    ///
    /// Los controles se buscan por identificador y no por su texto: "Empezar"
    /// aparece dos veces en el recorrido, y el texto visible cambia con el
    /// idioma.
    @MainActor
    private func startUsingTheApp(_ app: XCUIApplication) throws {
        let start = app.buttons["onboarding.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 10), "Se esperaba la bienvenida")
        start.tap()

        let nameField = app.textFields["companionForm.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Se esperaba el campo de nombre")
        nameField.tap()
        nameField.typeText("Luli")

        let save = app.buttons["companionForm.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5), "Se esperaba el botón de guardar")
        save.tap()

        XCTAssertTrue(
            app.buttons["dashboard.record"].waitForExistence(timeout: 10),
            "Se esperaba llegar al dashboard, con su acción de registrar a la vista"
        )
    }
}
