import Foundation
import SwiftData
import Testing

@testable import AppSaludAnimales

struct HistoryBuilderTests {
    private let container: ModelContainer
    private let context: ModelContext

    init() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    @Test
    func ordenaTodoDeLoMasNuevoALoMasViejo() throws {
        let companion = try makeCompanion()
        companion.notes.append(CompanionNote(text: "Vieja", date: .test(2024, 1, 10)))
        companion.measurements.append(
            HealthMeasurement(value: 24.3, date: .test(2024, 5, 20))
        )
        companion.episodes.append(HealthEpisode(symptom: "Tos", date: .test(2024, 3, 5)))

        let entries = HistoryBuilder.entries(for: companion)

        // Por categoría y no por texto: el peso se formatea según la región y
        // "24,3 kg" o "24.3 kg" no deberían decidir si la prueba pasa.
        #expect(entries.map(\.category) == [.measurement, .episode, .note])
    }

    @Test
    func agrupaPorMes() throws {
        let companion = try makeCompanion()
        companion.notes.append(CompanionNote(text: "Una", date: .test(2024, 5, 3)))
        companion.notes.append(CompanionNote(text: "Otra", date: .test(2024, 5, 20)))
        companion.notes.append(CompanionNote(text: "De abril", date: .test(2024, 4, 12)))

        let sections = HistoryBuilder.sections(for: companion, calendar: .test)

        #expect(sections.count == 2)
        #expect(sections.first?.id == "2024-05")
        #expect(sections.first?.entries.map(\.title) == ["Otra", "Una"])
        #expect(sections.last?.entries.map(\.title) == ["De abril"])
    }

    @Test
    func filtraPorCategoria() throws {
        let companion = try makeCompanion()
        companion.notes.append(CompanionNote(text: "Una nota", date: .test(2024, 5, 3)))
        companion.episodes.append(HealthEpisode(symptom: "Tos", date: .test(2024, 5, 4)))

        let soloEpisodios = HistoryBuilder.entries(for: companion, categories: [.episode])

        #expect(soloEpisodios.map(\.title) == ["Tos"])
    }

    @Test
    func sinFiltroDevuelveTodo() throws {
        let companion = try makeCompanion()
        companion.notes.append(CompanionNote(text: "Una nota", date: .test(2024, 5, 3)))
        companion.episodes.append(HealthEpisode(symptom: "Tos", date: .test(2024, 5, 4)))

        #expect(HistoryBuilder.entries(for: companion, categories: []).count == 2)
    }

    @Test
    func soloOfreceFiltrosDeCategoriasQueTienenAlgo() throws {
        let companion = try makeCompanion()
        companion.notes.append(CompanionNote(text: "Una nota", date: .test(2024, 5, 3)))
        companion.vaccinations.append(Vaccination(name: "Quíntuple", date: .test(2024, 5, 4)))

        let categories = HistoryBuilder.availableCategories(for: companion)

        #expect(categories.contains(.note))
        #expect(categories.contains(.vaccination))
        #expect(!categories.contains(.medication))
    }

    @Test
    func unTratamientoPreventivoSeCategorizaAparte() throws {
        let companion = try makeCompanion()
        companion.treatments.append(
            Treatment(name: "Antiparasitario", startDate: .test(2024, 5, 4), isPreventive: true)
        )

        #expect(HistoryBuilder.entries(for: companion).first?.category == .preventive)
    }

    @Test
    func cadaLineaLlevaElEstadoDeLoQueRepresenta() throws {
        let companion = try makeCompanion()
        companion.episodes.append(HealthEpisode(symptom: "Vómitos", date: .test(2024, 5, 4)))

        #expect(HistoryBuilder.entries(for: companion).first?.badge?.label == "Activo")
    }

    @Test
    func unHistorialVacioNoTieneSecciones() throws {
        let companion = try makeCompanion()

        #expect(HistoryBuilder.sections(for: companion, calendar: .test).isEmpty)
        #expect(HistoryBuilder.availableCategories(for: companion).isEmpty)
    }

    private func makeCompanion() throws -> Companion {
        let companion = Companion(name: "Luli", species: .dog)
        context.insert(companion)
        return companion
    }
}
