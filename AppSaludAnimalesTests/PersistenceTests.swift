import Foundation
import SwiftData
import Testing

@testable import AppSaludAnimales

/// Estas pruebas cargan el esquema completo: si una relación queda sin inversa
/// o un tipo no es compatible con la persistencia, fallan acá y no en el
/// dispositivo de una persona usuaria.
struct PersistenceTests {
    @Test
    func elEsquemaCompletoSeCargaYGuarda() throws {
        let context = try makeContext()

        let companion = Companion(name: "Luli", species: .dog, birthDate: .test(2020, 3, 15), birthDatePrecision: .exact)
        context.insert(companion)
        try context.save()

        let stored = try context.fetch(FetchDescriptor<Companion>())
        #expect(stored.count == 1)
        #expect(stored.first?.age?.years == CompanionAgeCalculator.age(
            birthDate: .test(2020, 3, 15),
            precision: .exact
        )?.years)
    }

    @Test
    func borrarUnCompanieroBorraSuInformacionDeSalud() throws {
        let context = try makeContext()

        let companion = Companion(name: "Rita", species: .cat)
        let medication = Medication(name: "Meloxicam")
        companion.medications.append(medication)
        context.insert(companion)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Medication>()).count == 1)

        context.delete(companion)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Medication>()).isEmpty)
    }

    @Test
    func elApodoGanaSobreElNombreParaMostrar() throws {
        let context = try makeContext()

        let companion = Companion(name: "Lulúbelle", nickname: "Luli", species: .dog)
        context.insert(companion)

        #expect(companion.displayName == "Luli")
    }

    @Test
    func lasMedicacionesActivasSeSeparanDeLasFinalizadas() throws {
        let context = try makeContext()

        let companion = Companion(name: "Luli")
        let activa = Medication(name: "Gabapentina", startDate: .test(2024, 1, 1))
        let finalizada = Medication(name: "Amoxicilina", startDate: .test(2023, 1, 1), endDate: .test(2023, 1, 10))
        companion.medications.append(contentsOf: [activa, finalizada])
        context.insert(companion)
        try context.save()

        #expect(companion.activeMedications.count == 1)
        #expect(companion.activeMedications.first?.name == "Gabapentina")
    }

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainerFactory.makeContainer(inMemory: true)
        return ModelContext(container)
    }
}
