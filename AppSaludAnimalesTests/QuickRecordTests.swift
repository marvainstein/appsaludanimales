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

struct MedicationDuplicationTests {
    @Test
    func reconoceElMismoNombreEscritoDistinto() {
        #expect(MedicationDuplicationCheck.isSameMedication("Vitamina", "vitamina"))
        #expect(MedicationDuplicationCheck.isSameMedication("Vitamina", "  VITAMINA  "))
        #expect(MedicationDuplicationCheck.isSameMedication("Gabapentina", "gabapentína"))
    }

    @Test
    func noConfundeMedicacionesDistintas() {
        #expect(!MedicationDuplicationCheck.isSameMedication("Vitamina", "Vitamina B12"))
        #expect(!MedicationDuplicationCheck.isSameMedication("Meloxicam", "Gabapentina"))
    }

    @Test
    func elAvisoProponeRegistrarUnaToma() {
        let message = MedicationDuplicationCheck.warningMessage(for: "Vitamina")

        #expect(message.contains("Vitamina"))
        #expect(message.contains("registrar una toma"))
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

/// Los horarios de una medicación.
struct MedicationScheduleTests {
    @Test("Una medicación cargada con momentos del día se lee con su hora")
    func lasViejasSeSiguenLeyendo() {
        let medication = Medication(name: "Fenobarbital")
        medication.timesOfDay = [.morning, .night]

        let times = MedicationSchedule.times(for: medication, calendar: .test)
        let hours = times.map { Calendar.test.component(.hour, from: $0) }

        #expect(
            hours == [8, 21],
            "Nadie puede perder lo que ya tenía cargado por un cambio de criterio nuestro"
        )
    }

    @Test("Los horarios exactos ganan sobre los momentos del día")
    func losHorariosExactosGanan() {
        let medication = Medication(name: "Fenobarbital")
        medication.timesOfDay = [.morning]
        medication.exactTimes = [.test(2026, 1, 1, hour: 7, minute: 30)]

        #expect(MedicationSchedule.times(for: medication, calendar: .test).count == 1)
    }

    @Test("Propone los repartos habituales al agregar horarios")
    func proponeLosRepartosHabituales() {
        var times: [Date] = []

        for expected in [8, 20, 12] {
            let suggestion = MedicationSchedule.nextSuggestedTime(after: times, calendar: .test)
            #expect(Calendar.test.component(.hour, from: suggestion) == expected)
            times.append(suggestion)
        }
    }

    @Test("Sin horarios no inventa una descripción")
    func sinHorariosNoDiceNada() {
        #expect(MedicationSchedule.description(for: Medication(name: "Vitamina")) == nil)
    }
}
