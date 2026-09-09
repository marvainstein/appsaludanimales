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
            Self.element(app, "quickRecord.weight").waitForExistence(timeout: 5),
            "Se esperaban las opciones del registro rápido"
        )

        try audit(app, pantalla: "el registro rápido", tipos: Self.sinTamanoDeTexto)
    }

    @MainActor
    func testElPerfilPasaLaAuditoria() throws {
        let app = launchApp(withCompanion: true)
        try waitForDashboard(app)

        Self.element(app, "dashboard.companion").tap()

        try audit(app, pantalla: "el perfil", tipos: Self.sinTamanoDeTexto)
    }

    @MainActor
    func testLaEvolucionDelPesoPasaLaAuditoria() throws {
        let app = launchApp(withCompanion: true)
        try open(app, "dashboard.companion", then: "profile.weight")

        try audit(app, pantalla: "la evolución del peso", tipos: Self.sinTamanoDeTexto)
    }

    @MainActor
    func testElRespaldoPasaLaAuditoria() throws {
        let app = launchApp(withCompanion: true)
        try open(app, "dashboard.companion", then: "profile.backup")

        try audit(app, pantalla: "el respaldo", tipos: Self.sinTamanoDeTexto)
    }

    @MainActor
    func testAcercaDePasaLaAuditoria() throws {
        let app = launchApp(withCompanion: true)
        try open(app, "dashboard.companion", then: "profile.about")

        try audit(app, pantalla: "acerca de", tipos: Self.sinTamanoDeTexto)
    }

    @MainActor
    func testLaDespedidaPasaLaAuditoria() throws {
        let app = launchApp(withCompanion: true)
        try open(app, "dashboard.companion", then: "profile.farewell")

        try audit(app, pantalla: "la despedida", tipos: Self.sinTamanoDeTexto)
    }

    @MainActor
    func testElModoEmergenciaPasaLaAuditoria() throws {
        let app = launchApp(withCompanion: true)
        try waitForDashboard(app)

        Self.element(app, "dashboard.emergency").tap()

        XCTAssertTrue(
            Self.element(app, "emergency.nearbyVets").waitForExistence(timeout: 5),
            "Se esperaba el modo emergencia"
        )

        try audit(app, pantalla: "el modo emergencia", tipos: Self.sinTamanoDeTexto)
    }

    /// La pantalla de veterinarias cerca, antes de pedir el permiso de
    /// ubicación. Lo que viene después depende de una respuesta del sistema y de
    /// la red, así que no entra en una prueba.
    @MainActor
    func testVeterinariasCercaPasaLaAuditoria() throws {
        let app = launchApp(withCompanion: true)
        try waitForDashboard(app)

        Self.element(app, "dashboard.emergency").tap()
        try tap(app, "emergency.nearbyVets")

        XCTAssertTrue(
            Self.element(app, "nearbyVets.search").waitForExistence(timeout: 5),
            "Se esperaba la pantalla de veterinarias cerca"
        )

        try audit(app, pantalla: "veterinarias cerca", tipos: Self.sinTamanoDeTexto)
    }

    // MARK: - Navegación

    /// Toca un control y espera a que aparezca el siguiente.
    @MainActor
    private func open(_ app: XCUIApplication, _ first: String, then second: String) throws {
        try waitForDashboard(app)
        try tap(app, first)
        try tap(app, second)
    }

    /// Busca un control, bajando por la pantalla si hace falta.
    ///
    /// En una lista, lo que está debajo del borde inferior todavía no existe
    /// para las pruebas: se crea recién cuando se llega scrolleando. Sin esto,
    /// una prueba falla por no encontrar algo que sí está, y el mensaje culpa al
    /// identificador cuando el problema era la altura.
    @MainActor
    private func tap(_ app: XCUIApplication, _ identifier: String) throws {
        let element = Self.element(app, identifier)

        if !element.waitForExistence(timeout: 5) || !element.isHittable {
            for _ in 0..<6 where !element.exists || !element.isHittable {
                app.swipeUp()
            }
        }

        XCTAssertTrue(
            element.exists && element.isHittable,
            "Se esperaba encontrar “\(identifier)” para seguir el recorrido"
        )

        element.tap()
    }

    // MARK: - Auditoría

    /// Todo menos el tamaño de texto.
    ///
    /// La verificación de Dynamic Type de Apple agranda el texto al máximo y
    /// vuelve a medir cada elemento. En una pantalla con una lista más larga que
    /// la pantalla, todo lo que queda debajo del borde inferior se mide sin
    /// haber crecido y se reporta como si su tipografía no escalara. Lo mismo
    /// pasa con los botones de la barra de navegación, que dibuja el sistema y
    /// que iOS no agranda por diseño.
    ///
    /// Se ve claro en la evidencia: en el registro rápido las seis filas usan la
    /// misma función y la misma tipografía, y solo se reportaban las cuatro de
    /// abajo. Si la fuente no escalara, se reportarían las seis.
    ///
    /// Así que en esas pantallas esta verificación puntual no dice nada útil, y
    /// dejarla reportando lo mismo en cada vuelta es peor que sacarla: enseña a
    /// ignorar el color rojo. El tamaño de texto en pantallas con lista se
    /// verifica a mano, con el teléfono y el texto al máximo, según el protocolo
    /// de docs/accesibilidad.md. Todo el resto de la auditoría sigue corriendo
    /// acá, incluidas las que sí encontraron problemas reales.
    private static let sinTamanoDeTexto: XCUIAccessibilityAuditType =
        XCUIAccessibilityAuditType.all.subtracting(.dynamicType)

    /// Corre la auditoría y, si algo falla, lo cuenta con nombre y apellido:
    /// qué pantalla, qué problema y sobre qué elemento.
    ///
    /// El mensaje que da XCTest por su cuenta obliga a abrir el detalle en Xcode
    /// para saber qué elemento está señalado. Acá lo dejamos escrito en la línea
    /// de la falla, que es lo único que se ve de un vistazo y lo único que se
    /// puede copiar y pegar para pedir ayuda.
    @MainActor
    private func audit(
        _ app: XCUIApplication,
        pantalla: String,
        tipos: XCUIAccessibilityAuditType = .all
    ) throws {
        var problemas: [String] = []

        try app.performAccessibilityAudit(for: tipos) { issue in
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

    /// Busca por identificador sin atarse al tipo de elemento.
    ///
    /// Cuando una vista arma su propio elemento de accesibilidad, lo que
    /// XCUITest ve puede dejar de ser un botón. Que la prueba se caiga por eso
    /// es ruido: lo que le importa es que el control esté y se pueda tocar.
    @MainActor
    private static func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

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
