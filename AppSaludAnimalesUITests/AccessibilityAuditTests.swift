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
    /// Si el recorrido hasta la pantalla falla, no tiene sentido auditar lo que
    /// haya quedado en pantalla: paramos ahí. La auditoría en sí junta todos sus
    /// hallazgos y los reporta de una sola vez, así que no pierde ninguno.
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testLaPrimeraPantallaPasaLaAuditoria() throws {
        let app = launchApp()

        try audit(app, pantalla: "la bienvenida")
    }

    @MainActor
    func testElDashboardPasaLaAuditoria() throws {
        let app = launchApp(withCompanion: true)
        try waitForDashboard(app)

        try audit(app, pantalla: "el dashboard")
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

        try audit(app, pantalla: "el registro rápido")
    }

    // MARK: - Auditoría

    /// Corre la auditoría y, si algo falla, lo cuenta con nombre y apellido:
    /// qué pantalla, qué problema y sobre qué elemento.
    ///
    /// El mensaje que da XCTest por su cuenta obliga a abrir el detalle en Xcode
    /// para saber qué elemento está señalado. Acá lo dejamos escrito en la línea
    /// de la falla, que es lo único que se ve de un vistazo y lo único que se
    /// puede copiar y pegar para pedir ayuda.
    @MainActor
    private func audit(_ app: XCUIApplication, pantalla: String) throws {
        var problemas: [String] = []

        try app.performAccessibilityAudit { issue in
            problemas.append(
                """
                • \(issue.compactDescription)
                  Elemento: \(Self.describe(issue.element))
                  Detalle: \(issue.detailedDescription)
                """
            )
            // Lo reportamos nosotros, más abajo y con más contexto.
            return true
        }

        if !problemas.isEmpty {
            XCTFail(
                """
                La auditoría de accesibilidad encontró \(problemas.count) \
                problema(s) en \(pantalla):

                \(problemas.joined(separator: "\n"))
                """
            )
        }
    }

    /// Descripción corta y legible de un elemento señalado por la auditoría.
    ///
    /// `debugDescription` de XCUIElement imprime el árbol entero y es ilegible;
    /// lo que sirve para encontrarlo en el código es el identificador, el texto
    /// y dónde está en pantalla.
    @MainActor
    private static func describe(_ element: XCUIElement?) -> String {
        guard let element else { return "sin elemento asociado" }

        var partes: [String] = ["tipo \(element.elementType.rawValue)"]

        if !element.identifier.isEmpty {
            partes.append("identificador “\(element.identifier)”")
        }

        if !element.label.isEmpty {
            partes.append("texto “\(element.label)”")
        }

        let marco = element.frame
        partes.append(
            "en x \(Int(marco.origin.x)), y \(Int(marco.origin.y)), "
            + "ancho \(Int(marco.width)), alto \(Int(marco.height))"
        )

        return partes.joined(separator: ", ")
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
