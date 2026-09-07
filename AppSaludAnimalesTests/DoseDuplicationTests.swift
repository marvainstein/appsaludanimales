import Foundation
import Testing

@testable import AppSaludAnimales

struct DoseDuplicationTests {
    @Test
    func avisaCuandoOtraPersonaRegistroLaDosisHacePoco() {
        let existing = RecordedDose(administeredAt: .test(2024, 5, 20, hour: 9, minute: 14), recordedByName: "Zoe")

        let conflict = DoseDuplicationCheck.conflictingDose(
            for: .test(2024, 5, 20, hour: 9, minute: 40),
            among: [existing]
        )

        #expect(conflict == existing)
    }

    @Test
    func noAvisaFueraDeLaVentana() {
        let existing = RecordedDose(administeredAt: .test(2024, 5, 20, hour: 9, minute: 0))

        let conflict = DoseDuplicationCheck.conflictingDose(
            for: .test(2024, 5, 20, hour: 21, minute: 0),
            among: [existing]
        )

        #expect(conflict == nil)
    }

    @Test
    func eligeLaDosisMasCercanaAlMomentoPropuesto() {
        let lejana = RecordedDose(administeredAt: .test(2024, 5, 20, hour: 8, minute: 15))
        let cercana = RecordedDose(administeredAt: .test(2024, 5, 20, hour: 8, minute: 55))

        let conflict = DoseDuplicationCheck.conflictingDose(
            for: .test(2024, 5, 20, hour: 9, minute: 0),
            among: [lejana, cercana]
        )

        #expect(conflict == cercana)
    }

    @Test
    func elAvisoEsUnaPreguntaYNoUnReproche() {
        let dose = RecordedDose(administeredAt: .test(2024, 5, 20, hour: 9, minute: 14), recordedByName: "Zoe")
        let message = DoseDuplicationCheck.warningMessage(for: dose)

        #expect(message.contains("Zoe"))
        #expect(message.contains("¿Querés registrarla igual?"))
    }
}
