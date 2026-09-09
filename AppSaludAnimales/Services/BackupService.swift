import Foundation
import SwiftData

/// Crear y restaurar el respaldo.
///
/// Restaurar **agrega, no reemplaza**. Cada registro viaja con su identificador,
/// así que restaurar el mismo archivo dos veces no duplica nada, y restaurar un
/// respaldo viejo sobre un teléfono en uso no borra lo cargado desde entonces.
/// Es la única forma de que restaurar "por las dudas" no pueda salir mal.
enum BackupService {
    // MARK: - Crear

    static func archive(for companions: [Companion], createdAt: Date = Date()) -> BackupArchive {
        BackupArchive(
            createdAt: createdAt,
            companions: companions.map(companionBackup)
        )
    }

    static func encode(_ archive: BackupArchive) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        // Legible por una persona: si esta app desaparece, la información no.
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(archive)
    }

    static func decode(_ data: Data) throws -> BackupArchive {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let archive = try? decoder.decode(BackupArchive.self, from: data) else {
            throw BackupError.unreadable
        }

        guard archive.formatVersion <= BackupArchive.currentFormatVersion else {
            throw BackupError.tooNew(version: archive.formatVersion)
        }

        return archive
    }

    static func fileName(createdAt: Date = Date()) -> String {
        let stamp = createdAt.formatted(
            .verbatim(
                "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)",
                timeZone: .current,
                calendar: .current
            )
        )

        return "Respaldo Salud Animal \(stamp).json"
    }

    // MARK: - Restaurar

    @MainActor
    static func restore(_ archive: BackupArchive, into context: ModelContext) throws -> BackupRestoreSummary {
        var summary = BackupRestoreSummary()

        let existingCompanions = try context.fetch(FetchDescriptor<Companion>())
        var byID = Dictionary(uniqueKeysWithValues: existingCompanions.map { ($0.id, $0) })

        for backup in archive.companions {
            let companion: Companion

            if let existing = byID[backup.id] {
                companion = existing
                summary.skippedRecords += 1
            } else {
                companion = Companion(name: backup.name)
                apply(backup, to: companion)
                context.insert(companion)
                byID[backup.id] = companion
                summary.addedCompanions += 1
            }

            restoreRecords(of: backup, into: companion, summary: &summary)
        }

        try context.save()
        return summary
    }

    // MARK: - Crear: modelo a respaldo

    private static func companionBackup(_ companion: Companion) -> CompanionBackup {
        CompanionBackup(
            id: companion.id,
            name: companion.name,
            nickname: companion.nickname,
            species: companion.speciesRawValue,
            breed: companion.breed,
            sex: companion.sexRawValue,
            birthDate: companion.birthDate,
            birthDatePrecision: companion.birthDatePrecisionRawValue,
            relevantConditions: companion.relevantConditions,
            allergies: companion.allergies,
            createdAt: companion.createdAt,
            updatedAt: companion.updatedAt,
            photoData: companion.photoData,
            photoAccessibilityDescription: companion.photoAccessibilityDescription,
            medications: companion.medications.map { medication in
                MedicationBackup(
                    id: medication.id,
                    name: medication.name,
                    activeIngredient: medication.activeIngredient,
                    dose: medication.dose,
                    doseUnit: medication.doseUnit,
                    frequency: medication.frequency,
                    administrationRoute: medication.administrationRoute,
                    indications: medication.indications,
                    notes: medication.notes,
                    startDate: medication.startDate,
                    endDate: medication.endDate,
                    isSuspended: medication.isSuspended,
                    reminderEnabled: medication.reminderEnabled,
                    createdAt: medication.createdAt,
                    timeOfDayRawValues: medication.timeOfDayRawValues,
                    exactTimes: medication.exactTimes,
                    doses: medication.doses.map {
                        DoseBackup(
                            id: $0.id,
                            administeredAt: $0.administeredAt,
                            notes: $0.notes,
                            recordedByName: $0.recordedByName,
                            createdAt: $0.createdAt
                        )
                    }
                )
            },
            treatments: companion.treatments.map {
                TreatmentBackup(
                    id: $0.id,
                    name: $0.name,
                    category: $0.category,
                    startDate: $0.startDate,
                    endDate: $0.endDate,
                    frequency: $0.frequency,
                    place: $0.place,
                    notes: $0.notes,
                    progressNotes: $0.progressNotes,
                    isSuspended: $0.isSuspended,
                    isPreventive: $0.isPreventive,
                    reminderEnabled: $0.reminderEnabled,
                    createdAt: $0.createdAt
                )
            },
            vaccinations: companion.vaccinations.map {
                VaccinationBackup(
                    id: $0.id,
                    name: $0.name,
                    date: $0.date,
                    nextDueDate: $0.nextDueDate,
                    notes: $0.notes,
                    reminderEnabled: $0.reminderEnabled,
                    createdAt: $0.createdAt
                )
            },
            episodes: companion.episodes.map {
                EpisodeBackup(
                    id: $0.id,
                    symptom: $0.symptom,
                    episodeDescription: $0.episodeDescription,
                    date: $0.date,
                    durationDescription: $0.durationDescription,
                    intensityRawValue: $0.intensityRawValue,
                    statusRawValue: $0.statusRawValue,
                    resolvedAt: $0.resolvedAt,
                    notes: $0.notes,
                    createdAt: $0.createdAt
                )
            },
            measurements: companion.measurements.map {
                MeasurementBackup(
                    id: $0.id,
                    kindRawValue: $0.kindRawValue,
                    value: $0.value,
                    unit: $0.unit,
                    date: $0.date,
                    notes: $0.notes,
                    createdAt: $0.createdAt
                )
            },
            appointments: companion.appointments.map {
                AppointmentBackup(
                    id: $0.id,
                    title: $0.title,
                    date: $0.date,
                    place: $0.place,
                    notes: $0.notes,
                    reminderEnabled: $0.reminderEnabled,
                    reminderLeadTimeMinutes: $0.reminderLeadTimeMinutes,
                    createdAt: $0.createdAt
                )
            },
            documents: companion.documents.map {
                DocumentBackup(
                    id: $0.id,
                    title: $0.title,
                    category: $0.category,
                    date: $0.date,
                    fileName: $0.fileName,
                    contentTypeIdentifier: $0.contentTypeIdentifier,
                    notes: $0.notes,
                    accessibilityDescription: $0.accessibilityDescription,
                    createdAt: $0.createdAt,
                    fileData: $0.fileData,
                    episodeID: $0.episode?.id,
                    appointmentID: $0.appointment?.id
                )
            },
            notes: companion.notes.map {
                NoteBackup(id: $0.id, text: $0.text, date: $0.date, createdAt: $0.createdAt)
            },
            professionals: companion.professionals.map {
                ProfessionalBackup(
                    id: $0.id,
                    name: $0.name,
                    role: $0.role,
                    clinic: $0.clinic,
                    phone: $0.phone,
                    email: $0.email,
                    notes: $0.notes,
                    isPrimaryVeterinarian: $0.isPrimaryVeterinarian,
                    createdAt: $0.createdAt
                )
            },
            responsiblePeople: companion.responsiblePeople.map {
                ResponsiblePersonBackup(
                    id: $0.id,
                    name: $0.name,
                    phone: $0.phone,
                    email: $0.email,
                    isPrimary: $0.isPrimary,
                    createdAt: $0.createdAt
                )
            }
        )
    }

    // MARK: - Restaurar: respaldo a modelo

    private static func apply(_ backup: CompanionBackup, to companion: Companion) {
        companion.id = backup.id
        companion.name = backup.name
        companion.nickname = backup.nickname
        companion.speciesRawValue = backup.species
        companion.breed = backup.breed
        companion.sexRawValue = backup.sex
        companion.birthDate = backup.birthDate
        companion.birthDatePrecisionRawValue = backup.birthDatePrecision
        companion.relevantConditions = backup.relevantConditions
        companion.allergies = backup.allergies
        companion.createdAt = backup.createdAt
        companion.updatedAt = backup.updatedAt
        companion.photoData = backup.photoData
        companion.photoAccessibilityDescription = backup.photoAccessibilityDescription
    }

    private static func restoreRecords(
        of backup: CompanionBackup,
        into companion: Companion,
        summary: inout BackupRestoreSummary
    ) {
        var episodesByID: [UUID: HealthEpisode] = [:]
        var appointmentsByID: [UUID: Appointment] = [:]

        for stored in companion.episodes { episodesByID[stored.id] = stored }
        for stored in companion.appointments { appointmentsByID[stored.id] = stored }

        add(backup.medications, existing: companion.medications, summary: &summary) { item in
            let medication = Medication(name: item.name, startDate: item.startDate)
            medication.id = item.id
            medication.activeIngredient = item.activeIngredient
            medication.dose = item.dose
            medication.doseUnit = item.doseUnit
            medication.frequency = item.frequency
            medication.administrationRoute = item.administrationRoute
            medication.indications = item.indications
            medication.notes = item.notes
            medication.endDate = item.endDate
            medication.isSuspended = item.isSuspended
            medication.reminderEnabled = item.reminderEnabled
            medication.createdAt = item.createdAt
            medication.timeOfDayRawValues = item.timeOfDayRawValues
            medication.exactTimes = item.exactTimes

            for dose in item.doses {
                let recorded = MedicationDose(administeredAt: dose.administeredAt)
                recorded.id = dose.id
                recorded.notes = dose.notes
                recorded.recordedByName = dose.recordedByName
                recorded.createdAt = dose.createdAt
                medication.doses.append(recorded)
            }

            companion.medications.append(medication)
        }

        add(backup.treatments, existing: companion.treatments, summary: &summary) { item in
            let treatment = Treatment(name: item.name, startDate: item.startDate)
            treatment.id = item.id
            treatment.category = item.category
            treatment.endDate = item.endDate
            treatment.frequency = item.frequency
            treatment.place = item.place
            treatment.notes = item.notes
            treatment.progressNotes = item.progressNotes
            treatment.isSuspended = item.isSuspended
            treatment.isPreventive = item.isPreventive
            treatment.reminderEnabled = item.reminderEnabled
            treatment.createdAt = item.createdAt
            companion.treatments.append(treatment)
        }

        add(backup.vaccinations, existing: companion.vaccinations, summary: &summary) { item in
            let vaccination = Vaccination(name: item.name, date: item.date)
            vaccination.id = item.id
            vaccination.nextDueDate = item.nextDueDate
            vaccination.notes = item.notes
            vaccination.reminderEnabled = item.reminderEnabled
            vaccination.createdAt = item.createdAt
            companion.vaccinations.append(vaccination)
        }

        add(backup.episodes, existing: companion.episodes, summary: &summary) { item in
            let episode = HealthEpisode(symptom: item.symptom, date: item.date)
            episode.id = item.id
            episode.episodeDescription = item.episodeDescription
            episode.durationDescription = item.durationDescription
            episode.intensityRawValue = item.intensityRawValue
            episode.statusRawValue = item.statusRawValue
            episode.resolvedAt = item.resolvedAt
            episode.notes = item.notes
            episode.createdAt = item.createdAt
            companion.episodes.append(episode)
            episodesByID[episode.id] = episode
        }

        add(backup.measurements, existing: companion.measurements, summary: &summary) { item in
            let measurement = HealthMeasurement(value: item.value, unit: item.unit, date: item.date)
            measurement.id = item.id
            measurement.kindRawValue = item.kindRawValue
            measurement.notes = item.notes
            measurement.createdAt = item.createdAt
            companion.measurements.append(measurement)
        }

        add(backup.appointments, existing: companion.appointments, summary: &summary) { item in
            let appointment = Appointment(title: item.title, date: item.date)
            appointment.id = item.id
            appointment.place = item.place
            appointment.notes = item.notes
            appointment.reminderEnabled = item.reminderEnabled
            appointment.reminderLeadTimeMinutes = item.reminderLeadTimeMinutes
            appointment.createdAt = item.createdAt
            companion.appointments.append(appointment)
            appointmentsByID[appointment.id] = appointment
        }

        add(backup.documents, existing: companion.documents, summary: &summary) { item in
            let document = HealthDocument(title: item.title, date: item.date)
            document.id = item.id
            document.category = item.category
            document.fileName = item.fileName
            document.contentTypeIdentifier = item.contentTypeIdentifier
            document.notes = item.notes
            document.accessibilityDescription = item.accessibilityDescription
            document.createdAt = item.createdAt
            document.fileData = item.fileData
            document.episode = item.episodeID.flatMap { episodesByID[$0] }
            document.appointment = item.appointmentID.flatMap { appointmentsByID[$0] }
            companion.documents.append(document)
        }

        add(backup.notes, existing: companion.notes, summary: &summary) { item in
            let note = CompanionNote(text: item.text, date: item.date)
            note.id = item.id
            note.createdAt = item.createdAt
            companion.notes.append(note)
        }

        add(backup.professionals, existing: companion.professionals, summary: &summary) { item in
            let professional = Professional(name: item.name)
            professional.id = item.id
            professional.role = item.role
            professional.clinic = item.clinic
            professional.phone = item.phone
            professional.email = item.email
            professional.notes = item.notes
            professional.isPrimaryVeterinarian = item.isPrimaryVeterinarian
            professional.createdAt = item.createdAt
            companion.professionals.append(professional)
        }

        add(backup.responsiblePeople, existing: companion.responsiblePeople, summary: &summary) { item in
            let person = ResponsiblePerson(name: item.name)
            person.id = item.id
            person.phone = item.phone
            person.email = item.email
            person.isPrimary = item.isPrimary
            person.createdAt = item.createdAt
            companion.responsiblePeople.append(person)
        }
    }

    /// Agrega solo lo que todavía no está, comparando por identificador.
    private static func add<Backup: BackupIdentifiable, Stored: PersistentIdentifiable>(
        _ items: [Backup],
        existing: [Stored],
        summary: inout BackupRestoreSummary,
        insert: (Backup) -> Void
    ) {
        let known = Set(existing.map(\.id))

        for item in items where !known.contains(item.id) {
            insert(item)
            summary.addedRecords += 1
        }

        summary.skippedRecords += items.filter { known.contains($0.id) }.count
    }
}

/// Todo lo que se respalda tiene identificador propio: es lo que permite
/// restaurar dos veces sin duplicar nada.
protocol BackupIdentifiable {
    var id: UUID { get }
}

protocol PersistentIdentifiable {
    var id: UUID { get }
}

extension MedicationBackup: BackupIdentifiable {}
extension TreatmentBackup: BackupIdentifiable {}
extension VaccinationBackup: BackupIdentifiable {}
extension EpisodeBackup: BackupIdentifiable {}
extension MeasurementBackup: BackupIdentifiable {}
extension AppointmentBackup: BackupIdentifiable {}
extension DocumentBackup: BackupIdentifiable {}
extension NoteBackup: BackupIdentifiable {}
extension ProfessionalBackup: BackupIdentifiable {}
extension ResponsiblePersonBackup: BackupIdentifiable {}

extension Medication: PersistentIdentifiable {}
extension Treatment: PersistentIdentifiable {}
extension Vaccination: PersistentIdentifiable {}
extension HealthEpisode: PersistentIdentifiable {}
extension HealthMeasurement: PersistentIdentifiable {}
extension Appointment: PersistentIdentifiable {}
extension HealthDocument: PersistentIdentifiable {}
extension CompanionNote: PersistentIdentifiable {}
extension Professional: PersistentIdentifiable {}
extension ResponsiblePerson: PersistentIdentifiable {}
