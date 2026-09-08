import Foundation
import SwiftData
import Testing

@testable import AppSaludAnimales

/// Editar un registro tiene que corregir lo que está mal sin perder lo que está
/// bien. Eso es lo que separa "editar" de "borrar y volver a cargar".
struct RecordEditingTests {
    @Test("Corregir una medicación conserva las tomas ya registradas")
    func editarUnaMedicacionConservaSusTomas() throws {
        let context = try makeContext()

        let companion = Companion(name: "Luli", species: .dog)
        let medication = Medication(name: "Meloxicán", dose: "media pastilla")
        medication.doses.append(MedicationDose(administeredAt: .test(2025, 5, 1, hour: 9)))
        medication.doses.append(MedicationDose(administeredAt: .test(2025, 5, 2, hour: 9)))
        companion.medications.append(medication)
        context.insert(companion)
        try context.save()

        // Lo que hace la pantalla de edición: cambia el registro que ya existe
        // en vez de crear uno nuevo.
        medication.name = "Meloxicam"
        medication.dose = "una pastilla"
        try context.save()

        let stored = try context.fetch(FetchDescriptor<Medication>())
        #expect(stored.count == 1, "Editar no debería dejar una medicación duplicada")
        #expect(stored.first?.name == "Meloxicam")
        #expect(stored.first?.dose == "una pastilla")
        #expect(
            stored.first?.doses.count == 2,
            "Las tomas registradas son historia clínica: corregir el nombre no puede borrarlas"
        )
    }

    @Test("Sacarle la fecha de la próxima vacuna la deja realmente sin fecha")
    func editarUnaVacunaPuedeVaciarLaProximaFecha() throws {
        let context = try makeContext()

        let companion = Companion(name: "Rita", species: .cat)
        let vaccination = Vaccination(name: "Triple", date: .test(2025, 3, 1))
        vaccination.nextDueDate = .test(2026, 3, 1)
        companion.vaccinations.append(vaccination)
        context.insert(companion)
        try context.save()

        vaccination.nextDueDate = nil
        try context.save()

        let stored = try context.fetch(FetchDescriptor<Vaccination>()).first
        #expect(stored?.nextDueDate == nil, "Un dato que se borra tiene que quedar borrado")
    }

    /// El peso se guarda como número y se edita como texto. Si el número
    /// guardado no se puede volver a leer, editar un peso lo rompería en
    /// silencio: el campo aparecería vacío o con el botón de guardar apagado.
    @Test("Un peso guardado se puede volver a leer para editarlo")
    func elPesoGuardadoVuelveAEntrarEnElFormulario() {
        for value in [24.3, 5.0, 0.75, 42.0, 199.9] {
            let asText = value.formatted()

            #expect(
                WeightInputParser.parse(asText) == value,
                "El peso \(asText) tendría que poder volver a editarse"
            )
        }
    }

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainerFactory.makeContainer(inMemory: true)
        return ModelContext(container)
    }
}
