import Foundation
import SwiftData

enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        Companion.self,
        Medication.self,
        MedicationDose.self,
        Treatment.self,
        TreatmentSession.self,
        Vaccination.self,
        HealthEpisode.self,
        HealthMeasurement.self,
        Appointment.self,
        HealthDocument.self,
        CompanionNote.self,
        Professional.self,
        ResponsiblePerson.self
    ]
}

enum ModelContainerFactory {
    /// La sincronización con iCloud se activa en V1, junto con el soporte de
    /// varias personas responsables. El esquema ya cumple sus requisitos: todas
    /// las propiedades tienen valor por defecto o son opcionales, y todas las
    /// relaciones tienen inversa.
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(AppSchema.models)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
