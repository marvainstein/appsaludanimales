import Foundation
import Testing

@testable import AppSaludAnimales

struct DocumentFileNameTests {
    @Test
    func armaUnNombreQueSeEntiende() {
        let name = DocumentFileName.make(
            companionName: "Luli",
            title: "Análisis de sangre",
            originalFileName: "informe_2024.pdf",
            defaultExtension: "dat"
        )

        #expect(name == "Luli - Análisis de sangre.pdf")
    }

    @Test
    func usaLaExtensionPorDefectoCuandoNoHayArchivoOriginal() {
        let name = DocumentFileName.make(
            companionName: "Luli",
            title: "Radiografía",
            originalFileName: nil,
            defaultExtension: "jpeg"
        )

        #expect(name == "Luli - Radiografía.jpeg")
    }

    @Test
    func quitaLosCaracteresQueRompenUnNombreDeArchivo() {
        let name = DocumentFileName.make(
            companionName: "Luli",
            title: "Análisis 12/05: sangre",
            originalFileName: nil,
            defaultExtension: "pdf"
        )

        #expect(!name.contains("/"))
        #expect(!name.contains(":"))
        #expect(name.hasSuffix(".pdf"))
    }

    @Test
    func sinTituloNiNombreUsaUnoDeRespaldo() {
        let name = DocumentFileName.make(
            companionName: "",
            title: "   ",
            originalFileName: nil,
            defaultExtension: "pdf"
        )

        #expect(name == "\(DocumentFileName.fallbackName).pdf")
    }

    @Test
    func normalizaLaExtensionAMinusculas() {
        let name = DocumentFileName.make(
            companionName: "Luli",
            title: "Eco",
            originalFileName: "ESTUDIO.PDF",
            defaultExtension: "dat"
        )

        #expect(name.hasSuffix(".pdf"))
    }

    @Test
    func lasCategoriasSugeridasTienenTexto() {
        #expect(!DocumentCategorySuggestions.all.isEmpty)
        #expect(DocumentCategorySuggestions.all.allSatisfy { !$0.isEmpty })
    }
}
