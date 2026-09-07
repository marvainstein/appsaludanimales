import Foundation
import SwiftData
import Testing

@testable import AppSaludAnimales

struct WeightInputParserTests {
    @Test
    func leeElPesoConComaDecimal() {
        #expect(WeightInputParser.parse("24,3") == 24.3)
    }

    @Test
    func leeElPesoConPuntoDecimal() {
        #expect(WeightInputParser.parse("24.3") == 24.3)
    }

    @Test
    func ignoraLosEspaciosAlrededor() {
        #expect(WeightInputParser.parse("  5,2  ") == 5.2)
    }

    @Test(arguments: ["", "abc", "0", "-3", "500"])
    func noAceptaLoQueNoEsUnPeso(text: String) {
        #expect(WeightInputParser.parse(text) == nil)
    }

    @Test
    func noMuestraAyudaMientrasElCampoEstaVacio() {
        #expect(WeightInputParser.guidance(for: "") == nil)
        #expect(WeightInputParser.guidance(for: "   ") == nil)
    }

    @Test
    func muestraAyudaCuandoLoEscritoNoEsUnPeso() {
        #expect(WeightInputParser.guidance(for: "veinticuatro") != nil)
    }

    @Test
    func noMuestraAyudaCuandoElPesoEsValido() {
        #expect(WeightInputParser.guidance(for: "24,3") == nil)
    }
}

struct SymptomSuggestionsTests {
    @Test
    func sinTextoOfreceLasSugerenciasMasFrecuentes() {
        let suggestions = SymptomSuggestions.matching("")

        #expect(suggestions.count == 6)
        #expect(suggestions.first == "Vómitos")
    }

    @Test
    func encuentraSugerenciasSinImportarLosAcentos() {
        #expect(SymptomSuggestions.matching("vomitos").contains("Vómitos"))
        #expect(SymptomSuggestions.matching("VÓMITOS").contains("Vómitos"))
    }

    @Test
    func noSugiereNadaParaAlgoQueNoEstaEnLaLista() {
        #expect(SymptomSuggestions.matching("cojera").isEmpty)
    }
}

struct DoseRecordingTests {
    private let container: ModelContainer
    private let context: ModelContext

    init() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    @Test
    func registrarUnaTomaLaAsociaALaMedicacion() throws {
        let medication = try makeMedication()

        medication.doses.append(MedicationDose(administeredAt: .test(2024, 5, 20, hour: 9)))
        try context.save()

        #expect(medication.doses.count == 1)
        #expect(medication.recordedDoses.first?.administeredAt == .test(2024, 5, 20, hour: 9))
    }

    @Test
    func avisaCuandoYaHayUnaTomaCercana() throws {
        let medication = try makeMedication()
        medication.doses.append(
            MedicationDose(administeredAt: .test(2024, 5, 20, hour: 9), recordedByName: "Zoe")
        )

        let conflict = medication.conflictingDose(for: .test(2024, 5, 20, hour: 9, minute: 30))

        #expect(conflict != nil)
        #expect(conflict?.recordedByName == "Zoe")
    }

    @Test
    func noAvisaCuandoLaTomaAnteriorFueHaceRato() throws {
        let medication = try makeMedication()
        medication.doses.append(MedicationDose(administeredAt: .test(2024, 5, 20, hour: 9)))

        #expect(medication.conflictingDose(for: .test(2024, 5, 20, hour: 21)) == nil)
    }

    private func makeMedication() throws -> Medication {
        let companion = Companion(name: "Luli")
        let medication = Medication(name: "Gabapentina", dose: "media pastilla")
        companion.medications.append(medication)
        context.insert(companion)
        try context.save()
        return medication
    }
}

struct EpisodeIntensityTests {
    @Test(arguments: EpisodeIntensity.allCases)
    func cadaNivelTieneUnNombreEnTexto(level: EpisodeIntensity) {
        #expect(!level.label.isEmpty)
    }

    @Test
    func laIntensidadSeGuardaYSeLeeComoTexto() {
        let episode = HealthEpisode(symptom: "Tos", date: .test(2024, 5, 20))

        #expect(episode.intensity == nil)
        #expect(episode.intensityLabel == nil)

        episode.intensity = .moderate

        #expect(episode.intensityRawValue == 2)
        #expect(episode.intensityLabel == "Intensidad moderada")
    }
}
