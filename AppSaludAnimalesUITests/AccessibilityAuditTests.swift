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
        let app = launchApp(withCompanion: true)
        try waitForDashboard(app)

        try app.performAccessibilityAudit()
    }

    @MainActor
    func testElRegistroRapidoPasaLaAuditoria() throws {
        let app = launchApp(withCompanion: true)
        try waitForDashboard(app)

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
    ///
    /// Con `withCompanion` arranca además con un compañero ya cargado, así la
    /// prueba audita la pantalla que le interesa sin depender de completar un
    /// formulario por el camino.
    @MainActor
    private func launchApp(withCompanion: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-uiTesting")

        if withCompanion {
            app.launchArguments.append("-uiTestingSeedCompanion")
        }

        app.launch()
        return app
    }

    @MainActor
    private func waitForDashboard(_ app: XCUIApplication) throws {
        XCTAssertTrue(
            app.buttons["dashboard.record"].waitForExistence(timeout: 10),
            "Se esperaba el dashboard, con su acción de registrar a la vista"
        )
    }
}
