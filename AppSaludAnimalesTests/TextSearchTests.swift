import Foundation
import SwiftData
import Testing

@testable import AppSaludAnimales

/// Buscar en castellano, escribiendo con el pulgar y sin tildes.
struct TextSearchTests {
    @Test("Encuentra sin tildes y sin distinguir mayúsculas")
    func encuentraSinTildes() {
        #expect(TextSearch.matches("Análisis de sangre", query: "analisis"))
        #expect(TextSearch.matches("Análisis de sangre", query: "ANALISIS"))
        #expect(TextSearch.matches("Ecografía abdominal", query: "ecografia"))
        #expect(TextSearch.matches("Convulsión", query: "convulsion"))
    }

    @Test("Y al revés: con tildes encuentra lo escrito sin ellas")
    func tambienAlReves() {
        #expect(TextSearch.matches("Analisis de sangre", query: "análisis"))
    }

    @Test("Una búsqueda vacía no filtra nada")
    func laBusquedaVaciaNoFiltra() {
        #expect(TextSearch.matches("Cualquier cosa", query: ""))
        #expect(TextSearch.matches("Cualquier cosa", query: "   "))
    }

    @Test("No inventa coincidencias")
    func noInventaCoincidencias() {
        #expect(!TextSearch.matches("Análisis de sangre", query: "radiografía"))
        #expect(!TextSearch.matches(nil, query: "algo"))
    }

    @Test("Busca en varios campos: alcanza con que aparezca en uno")
    func buscaEnVariosCampos() {
        #expect(TextSearch.matchesAny(["Vitamina B", nil, "Medicación"], query: "medicacion"))
        #expect(!TextSearch.matchesAny(["Vitamina B", nil, "Medicación"], query: "vacuna"))
    }
}

/// La búsqueda dentro del historial, que es donde se usa de verdad.
@MainActor
struct HistorySearchTests {
    @Test("Buscar por el nombre de la categoría trae todo lo de esa categoría")
    func buscarPorCategoria() throws {
        let companion = try companionWithRecords()

        let found = HistoryBuilder.entries(for: companion, search: "vacuna")

        #expect(found.count == 1)
        #expect(found.first?.title == "Triple")
    }

    @Test("Buscar sin tildes encuentra lo que sí las tiene")
    func buscarSinTildes() throws {
        let companion = try companionWithRecords()

        #expect(HistoryBuilder.entries(for: companion, search: "convulsion").count == 1)
    }

    @Test("La búsqueda y el filtro se aplican juntos")
    func laBusquedaYElFiltroSeSuman() throws {
        let companion = try companionWithRecords()

        let found = HistoryBuilder.entries(
            for: companion,
            categories: [.episode],
            search: "triple"
        )

        #expect(found.isEmpty, "Una vacuna no aparece cuando se está filtrando por episodios")
    }

    private func companionWithRecords() throws -> Companion {
        let context = ModelContext(try ModelContainerFactory.makeContainer(inMemory: true))

        let companion = Companion(name: "Luli", species: .dog)
        companion.vaccinations.append(Vaccination(name: "Triple", date: .test(2025, 3, 1)))
        companion.episodes.append(HealthEpisode(symptom: "Convulsión", date: .test(2025, 4, 1)))
        companion.notes.append(CompanionNote(text: "Durmió toda la tarde", date: .test(2025, 5, 1)))

        context.insert(companion)
        try context.save()

        return companion
    }
}
