import Foundation
import SwiftData
import Testing

@testable import AppSaludAnimales

/// El respaldo es la única red que hay contra perder años de historia clínica.
/// Si falla, falla en silencio y se descubre el día que ya no hay nada que
/// hacer. Por eso estas pruebas son más desconfiadas que el resto.
@MainActor
struct BackupTests {
    @Test("Ida y vuelta: lo que entra al respaldo vuelve igual")
    func elRespaldoConservaTodo() throws {
        let origin = try makeContext()
        let companion = fullCompanion()
        origin.insert(companion)
        try origin.save()

        let data = try BackupService.encode(BackupService.archive(for: [companion]))

        let destination = try makeContext()
        let summary = try BackupService.restore(BackupService.decode(data), into: destination)

        #expect(summary.addedCompanions == 1)

        let restored = try #require(try destination.fetch(FetchDescriptor<Companion>()).first)

        #expect(restored.id == companion.id)
        #expect(restored.name == "Luli")
        #expect(restored.nickname == "Lu")
        #expect(restored.species == .dog)
        #expect(restored.allergies == "Polen")
        #expect(restored.photoData == Data([0x09]))

        #expect(restored.medications.count == 1)
        #expect(restored.medications.first?.name == "Meloxicam")
        #expect(restored.medications.first?.timesOfDay == [.morning, .night])
        #expect(
            restored.medications.first?.doses.count == 2,
            "Las tomas registradas son historia clínica y tienen que viajar en el respaldo"
        )

        #expect(restored.episodes.first?.symptom == "Cojera")
        #expect(restored.episodes.first?.status == .monitoring)
        #expect(restored.measurements.first?.value == 24.3)
        #expect(restored.vaccinations.first?.nextDueDate != nil)
        #expect(restored.notes.first?.text == "Le gusta dormir al sol")
        #expect(restored.professionals.first?.isPrimaryVeterinarian == true)
        #expect(restored.responsiblePeople.count == 2)

        let document = try #require(restored.documents.first)
        #expect(document.fileData == Data([0x01, 0x02, 0x03]), "El archivo adjunto es lo más irrecuperable")
        #expect(document.episode?.id == companion.episodes.first?.id, "El vínculo con su episodio no se pierde")
    }

    @Test("Restaurar dos veces el mismo archivo no duplica nada")
    func restaurarDosVecesNoDuplica() throws {
        let origin = try makeContext()
        let companion = fullCompanion()
        origin.insert(companion)
        try origin.save()

        let data = try BackupService.encode(BackupService.archive(for: [companion]))
        let destination = try makeContext()

        _ = try BackupService.restore(BackupService.decode(data), into: destination)
        let second = try BackupService.restore(BackupService.decode(data), into: destination)

        #expect(second.addedCompanions == 0)
        #expect(second.addedRecords == 0)
        #expect(second.skippedRecords > 0)
        #expect(try destination.fetch(FetchDescriptor<Companion>()).count == 1)
        #expect(try destination.fetch(FetchDescriptor<Medication>()).count == 1)
        #expect(try destination.fetch(FetchDescriptor<HealthDocument>()).count == 1)
    }

    @Test("Restaurar un respaldo viejo no borra lo cargado después")
    func restaurarNoPisaLoNuevo() throws {
        let origin = try makeContext()
        let companion = fullCompanion()
        origin.insert(companion)
        try origin.save()

        let old = try BackupService.encode(BackupService.archive(for: [companion]))

        // Después del respaldo se sigue usando la app.
        companion.measurements.append(HealthMeasurement(value: 25.0, unit: "kg", date: .test(2025, 8, 1)))
        try origin.save()

        _ = try BackupService.restore(BackupService.decode(old), into: origin)

        #expect(
            companion.measurements.count == 2,
            "Restaurar por las dudas no puede borrar lo que se cargó desde el respaldo"
        )
    }

    @Test("Un archivo que no es un respaldo se rechaza con un mensaje claro")
    func rechazaUnArchivoQueNoEsUnRespaldo() {
        #expect(throws: BackupError.self) {
            try BackupService.decode(Data("esto no es un respaldo".utf8))
        }
    }

    @Test("Un respaldo de una versión más nueva se rechaza en vez de importarse a medias")
    func rechazaUnFormatoMasNuevo() throws {
        var archive = BackupService.archive(for: [])
        archive.formatVersion = BackupArchive.currentFormatVersion + 1

        let data = try BackupService.encode(archive)

        #expect(throws: BackupError.self) {
            try BackupService.decode(data)
        }
    }

    // MARK: - Ayudas

    private func makeContext() throws -> ModelContext {
        ModelContext(try ModelContainerFactory.makeContainer(inMemory: true))
    }

    /// Un compañero con algo de cada cosa: si el respaldo se olvida de un tipo
    /// de registro, esta prueba lo encuentra.
    private func fullCompanion() -> Companion {
        let companion = Companion(
            name: "Luli",
            nickname: "Lu",
            species: .dog,
            birthDate: .test(2020, 3, 15),
            birthDatePrecision: .exact
        )
        companion.allergies = "Polen"
        companion.photoData = Data([0x09])

        let medication = Medication(name: "Meloxicam", dose: "media pastilla")
        medication.timesOfDay = [.morning, .night]
        medication.doses.append(MedicationDose(administeredAt: .test(2025, 5, 1, hour: 9)))
        medication.doses.append(MedicationDose(administeredAt: .test(2025, 5, 1, hour: 21)))
        companion.medications.append(medication)

        let episode = HealthEpisode(symptom: "Cojera", date: .test(2025, 4, 2))
        episode.status = .monitoring
        companion.episodes.append(episode)

        companion.measurements.append(
            HealthMeasurement(value: 24.3, unit: "kg", date: .test(2025, 4, 1))
        )

        let vaccination = Vaccination(name: "Triple", date: .test(2025, 3, 1))
        vaccination.nextDueDate = .test(2026, 3, 1)
        companion.vaccinations.append(vaccination)

        let document = HealthDocument(title: "Análisis de sangre", date: .test(2025, 4, 3))
        document.fileData = Data([0x01, 0x02, 0x03])
        document.fileName = "analisis.pdf"
        document.episode = episode
        companion.documents.append(document)

        companion.notes.append(CompanionNote(text: "Le gusta dormir al sol", date: .test(2025, 4, 4)))

        companion.professionals.append(
            Professional(name: "Dra. Pérez", phone: "1122334455", isPrimaryVeterinarian: true)
        )
        companion.responsiblePeople.append(ResponsiblePerson(name: "Tomás", isPrimary: true))
        companion.responsiblePeople.append(ResponsiblePerson(name: "Ana"))

        return companion
    }
}
