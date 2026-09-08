import Foundation
import Testing

@testable import AppSaludAnimales

/// Traer treinta estudios de una solo sirve si la app hace el trabajo aburrido.
/// Estas pruebas cubren justamente eso: lo que la app deduce sola del nombre del
/// archivo, y qué pasa cuando se equivocaría.
struct DocumentBatchImportTests {
    // MARK: - Fecha

    @Test("Reconoce la fecha escrita en el nombre del archivo")
    func reconoceFormatosHabituales() throws {
        let cases: [(String, (Int, Int, Int))] = [
            ("analisis_2024-03-12", (2024, 3, 12)),
            ("Ecografia 12-03-2024", (2024, 3, 12)),
            ("20240312 hemograma", (2024, 3, 12)),
            ("radiografia.2024.03.12", (2024, 3, 12)),
            ("12_03_2024 control", (2024, 3, 12)),
            // Un número de más atrás no arruina la fecha que sí está.
            ("receta 2024-03-12-04", (2024, 3, 12))
        ]

        for (fileName, expected) in cases {
            let detected = try #require(
                DocumentBatchImport.detectedDate(in: fileName, calendar: .test, now: .test(2026, 1, 1)),
                "Se esperaba reconocer la fecha en “\(fileName)”"
            )

            let components = Calendar.test.dateComponents([.year, .month, .day], from: detected.date)
            #expect(components.year == expected.0)
            #expect(components.month == expected.1)
            #expect(components.day == expected.2)
        }
    }

    @Test("No inventa una fecha cuando el número no es una")
    func descartaLoQueNoEsUnaFecha() {
        let notDates = [
            "analisis 2024-13-45",   // mes y día imposibles
            "estudio 99-99-9999",
            "hemograma 123456",      // no tiene forma de fecha
            "control sin numeros"
        ]

        for fileName in notDates {
            let detected = DocumentBatchImport.detectedDate(
                in: fileName,
                calendar: .test,
                now: .test(2026, 1, 1)
            )

            if let detected {
                Issue.record("“\(fileName)” no debería dar una fecha, y dio \(detected.date)")
            }
        }
    }

    @Test("Una fecha futura se descarta: un estudio no puede ser de mañana")
    func descartaFechasFuturas() {
        let detected = DocumentBatchImport.detectedDate(
            in: "analisis 2030-05-01",
            calendar: .test,
            now: .test(2026, 1, 1)
        )

        #expect(detected == nil)
    }

    // MARK: - Título

    @Test("Propone un título legible a partir del nombre del archivo")
    func proponeUnTituloLegible() {
        let draft = DocumentBatchImport.draft(
            fileName: "analisis_de_sangre_2024-03-12.pdf",
            data: Data([0x01]),
            contentTypeIdentifier: "com.adobe.pdf",
            fallbackDate: .test(2026, 1, 1),
            calendar: .test
        )

        #expect(draft.title == "Analisis de sangre")
        #expect(Calendar.test.dateComponents([.year, .month, .day], from: draft.date).day == 12)
        #expect(draft.isReady)
    }

    @Test("Un archivo que solo tiene su fecha queda sin título, para que se escriba")
    func noInventaUnTituloQueNoExiste() {
        let draft = DocumentBatchImport.draft(
            fileName: "2024-03-12.pdf",
            data: Data([0x01]),
            contentTypeIdentifier: "com.adobe.pdf",
            fallbackDate: .test(2026, 1, 1),
            calendar: .test
        )

        #expect(draft.title.isEmpty)
        #expect(!draft.isReady, "Sin título no se puede guardar: después sería imposible de encontrar")
    }

    @Test("Una foto sin nombre de archivo usa la fecha de hoy y espera un título")
    func unaFotoQuedaEsperandoTitulo() {
        let today = Date.test(2026, 1, 1)
        let draft = DocumentBatchImport.draft(
            fileName: nil,
            data: Data([0x01]),
            contentTypeIdentifier: "public.jpeg",
            fallbackDate: today,
            calendar: .test
        )

        #expect(draft.title.isEmpty)
        #expect(draft.date == today)
    }

    // MARK: - Resumen

    @Test("Dice cuántos títulos faltan, sin reprochar")
    func cuentaLoQueFalta() {
        let drafts = [
            draft(title: "Análisis"),
            draft(title: ""),
            draft(title: "   ")
        ]

        #expect(DocumentBatchImport.pendingTitleMessage(for: drafts) != nil)
        #expect(DocumentBatchImport.pendingTitleMessage(for: [draft(title: "Análisis")]) == nil)
    }

    private func draft(title: String) -> DocumentImportDraft {
        DocumentImportDraft(
            title: title,
            date: .test(2026, 1, 1),
            fileName: nil,
            contentTypeIdentifier: nil,
            data: Data()
        )
    }
}
