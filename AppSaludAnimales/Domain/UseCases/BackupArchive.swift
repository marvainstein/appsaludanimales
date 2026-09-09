import Foundation

/// El respaldo, como estructura de datos pura.
///
/// Toda la historia de salud vive adentro del teléfono. Si el teléfono se pierde,
/// se rompe o se lo roban, se pierde todo: años de estudios, medicaciones y
/// episodios que no se pueden reconstruir. Un respaldo exportable es la única
/// respuesta a eso que no obliga a confiarle los datos a nadie.
///
/// El archivo es JSON legible a propósito. Si algún día esta app deja de existir,
/// la información tiene que poder abrirse igual: un respaldo que solo entiende el
/// programa que lo escribió no es un respaldo, es una jaula.
struct BackupArchive: Codable {
    /// Sube cuando el formato cambia de una manera que las versiones viejas no
    /// pueden leer. Restaurar un archivo de una versión más nueva se rechaza con
    /// un mensaje claro en vez de importar la mitad y romper el resto.
    static let currentFormatVersion = 1

    var formatVersion: Int = BackupArchive.currentFormatVersion
    var createdAt: Date
    var companions: [CompanionBackup]
}

struct CompanionBackup: Codable {
    var id: UUID
    var name: String
    var nickname: String?
    var species: String
    var breed: String?
    var sex: String
    var birthDate: Date?
    var birthDatePrecision: String
    var relevantConditions: String?
    var allergies: String?
    var createdAt: Date
    var updatedAt: Date
    var photoData: Data?
    var photoAccessibilityDescription: String?

    var medications: [MedicationBackup] = []
    var treatments: [TreatmentBackup] = []
    var vaccinations: [VaccinationBackup] = []
    var episodes: [EpisodeBackup] = []
    var measurements: [MeasurementBackup] = []
    var appointments: [AppointmentBackup] = []
    var documents: [DocumentBackup] = []
    var notes: [NoteBackup] = []
    var professionals: [ProfessionalBackup] = []
    var responsiblePeople: [ResponsiblePersonBackup] = []
}

struct MedicationBackup: Codable {
    var id: UUID
    var name: String
    var activeIngredient: String?
    var dose: String?
    var doseUnit: String?
    var frequency: String?
    var administrationRoute: String?
    var indications: String?
    var notes: String?
    var startDate: Date
    var endDate: Date?
    var isSuspended: Bool
    var reminderEnabled: Bool
    var createdAt: Date
    var timeOfDayRawValues: [String]
    var exactTimes: [Date]
    var doses: [DoseBackup]
}

struct DoseBackup: Codable {
    var id: UUID
    var administeredAt: Date
    var notes: String?
    var recordedByName: String?
    var createdAt: Date
}

struct TreatmentBackup: Codable {
    var id: UUID
    var name: String
    var category: String?
    var startDate: Date
    var endDate: Date?
    var frequency: String?
    var place: String?
    var notes: String?
    var progressNotes: String?
    var isSuspended: Bool
    var isPreventive: Bool
    var reminderEnabled: Bool
    var createdAt: Date
}

struct VaccinationBackup: Codable {
    var id: UUID
    var name: String
    var date: Date
    var nextDueDate: Date?
    var notes: String?
    var reminderEnabled: Bool
    var createdAt: Date
}

struct EpisodeBackup: Codable {
    var id: UUID
    var symptom: String
    var episodeDescription: String?
    var date: Date
    var durationDescription: String?
    var intensityRawValue: Int?
    var statusRawValue: String
    var resolvedAt: Date?
    var notes: String?
    var createdAt: Date
}

struct MeasurementBackup: Codable {
    var id: UUID
    var kindRawValue: String
    var value: Double
    var unit: String
    var date: Date
    var notes: String?
    var createdAt: Date
}

struct AppointmentBackup: Codable {
    var id: UUID
    var title: String
    var date: Date
    var place: String?
    var notes: String?
    var reminderEnabled: Bool
    var reminderLeadTimeMinutes: Int
    var createdAt: Date
}

struct DocumentBackup: Codable {
    var id: UUID
    var title: String
    var category: String?
    var date: Date
    var fileName: String?
    var contentTypeIdentifier: String?
    var notes: String?
    var accessibilityDescription: String?
    var createdAt: Date
    var fileData: Data?
    /// A qué episodio o turno estaba enganchado, para no perder el vínculo.
    var episodeID: UUID?
    var appointmentID: UUID?
}

struct NoteBackup: Codable {
    var id: UUID
    var text: String
    var date: Date
    var createdAt: Date
}

struct ProfessionalBackup: Codable {
    var id: UUID
    var name: String
    var role: String?
    var clinic: String?
    var phone: String?
    var email: String?
    var notes: String?
    var isPrimaryVeterinarian: Bool
    var createdAt: Date
}

struct ResponsiblePersonBackup: Codable {
    var id: UUID
    var name: String
    var phone: String?
    var email: String?
    var isPrimary: Bool
    var createdAt: Date
}

/// Qué pasó al restaurar, contado en número de registros.
///
/// Restaurar no reemplaza nada: agrega lo que falta y deja intacto lo que ya
/// está. Alguien que restaura por las dudas no puede perder lo que cargó hoy.
struct BackupRestoreSummary: Equatable {
    var addedCompanions = 0
    var addedRecords = 0
    var skippedRecords = 0

    var isEmpty: Bool {
        addedCompanions == 0 && addedRecords == 0
    }

    var message: String {
        guard !isEmpty else {
            return String(localized: "Este respaldo ya estaba cargado entero. No hizo falta agregar nada.")
        }

        var parts: [String] = []

        if addedCompanions > 0 {
            parts.append(addedCompanions == 1
                ? String(localized: "1 compañero")
                : String(localized: "\(addedCompanions) compañeros"))
        }

        if addedRecords > 0 {
            parts.append(addedRecords == 1
                ? String(localized: "1 registro")
                : String(localized: "\(addedRecords) registros"))
        }

        let added = String(localized: "Se agregaron \(parts.formatted(.list(type: .and))).")

        guard skippedRecords > 0 else { return added }

        return added + " " + String(localized: "Otros \(skippedRecords) ya estaban y se dejaron como estaban.")
    }
}

enum BackupError: LocalizedError {
    case unreadable
    case tooNew(version: Int)

    var errorDescription: String? {
        switch self {
        case .unreadable:
            String(localized: "Ese archivo no parece un respaldo de esta app.")
        case let .tooNew(version):
            String(localized: "Ese respaldo lo hizo una versión más nueva de la app (formato \(version)). Actualizá la app y volvé a intentar.")
        }
    }
}
