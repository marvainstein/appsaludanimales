import Foundation
import SwiftData
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

/// Un documento enganchado a un episodio o a un turno.
@MainActor
struct DocumentAttachmentTests {
    @Test("El documento adjunto sigue siendo del compañero, no solo del episodio")
    func elAdjuntoSigueSiendoDelCompaniero() throws {
        let context = ModelContext(try ModelContainerFactory.makeContainer(inMemory: true))

        let companion = Companion(name: "Luli", species: .dog)
        let episode = HealthEpisode(symptom: "Cojera", date: .test(2025, 4, 1))
        companion.episodes.append(episode)

        let document = HealthDocument(title: "Radiografía de cadera", date: .test(2025, 4, 2))
        companion.documents.append(document)
        document.episode = episode

        context.insert(companion)
        try context.save()

        #expect(episode.documents.count == 1, "Aparece adentro del episodio")
        #expect(
            companion.documents.count == 1,
            "Y sigue en la lista del compañero: si no, desaparecería del historial y del PDF"
        )
        #expect(HistoryBuilder.entries(for: companion, categories: [.document]).count == 1)
    }

    @Test("Borrar el episodio no se lleva el estudio puesto")
    func borrarElEpisodioNoSeLlevaElEstudio() throws {
        let context = ModelContext(try ModelContainerFactory.makeContainer(inMemory: true))

        let companion = Companion(name: "Luli", species: .dog)
        let episode = HealthEpisode(symptom: "Cojera", date: .test(2025, 4, 1))
        companion.episodes.append(episode)

        let document = HealthDocument(title: "Radiografía de cadera", date: .test(2025, 4, 2))
        companion.documents.append(document)
        document.episode = episode

        context.insert(companion)
        try context.save()

        context.delete(episode)
        try context.save()

        #expect(
            try context.fetch(FetchDescriptor<HealthDocument>()).count == 1,
            "Una radiografía cuesta plata y no se puede repetir: no se va con el episodio"
        )
    }
}
