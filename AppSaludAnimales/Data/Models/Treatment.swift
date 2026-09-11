import Foundation
import SwiftData

/// Tratamiento o tratamiento preventivo.
///
/// `category` es texto libre respaldado por sugerencias, no un enum cerrado: así
/// se puede registrar una terapia que la app no conoce sin migrar el esquema.
@Model
final class Treatment {
    var id: UUID = UUID()
    var name: String = ""
    var category: String?
    var startDate: Date = Date()
    var endDate: Date?
    var frequency: String?
    var place: String?
    var notes: String?
    var progressNotes: String?
    var isSuspended: Bool = false
    var isPreventive: Bool = false
    var reminderEnabled: Bool = false
    var createdAt: Date = Date()

    var companion: Companion?
    var professional: Professional?

    @Relationship(deleteRule: .cascade, inverse: \TreatmentSession.treatment)
    var sessions: [TreatmentSession] = []

    init(
        name: String = "",
        category: String? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isPreventive: Bool = false
    ) {
        self.name = name
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.isPreventive = isPreventive
    }
}

extension Treatment {
    func status(on referenceDate: Date = .now) -> ActivityStatus {
        MedicationStatusResolver.status(
            startDate: startDate,
            endDate: endDate,
            isSuspended: isSuspended,
            on: referenceDate
        )
    }
}

/// Cada vez que el animal fue.
///
/// La frecuencia de un tratamiento no es un dato fijo: Luli empezó yendo a
/// fisioterapia dos veces por semana, después cada quince días, y fue cambiando
/// toda su vida. El campo `frequency` dice cómo es ahora; estas sesiones dicen
/// cómo fue.
@Model
final class TreatmentSession {
    var id: UUID = UUID()
    var attendedAt: Date = Date()
    var notes: String?

    /// Quién la anotó. Con dos personas cuidando, saber quién anotó qué es más
    /// útil que impedir un registro doble.
    var recordedByName: String?
    var createdAt: Date = Date()

    var treatment: Treatment?

    init(attendedAt: Date = Date(), recordedByName: String? = nil, notes: String? = nil) {
        self.attendedAt = attendedAt
        self.recordedByName = recordedByName
        self.notes = notes
    }
}

extension Treatment {
    var recordedSessions: [RecordedDose] {
        sessions.map {
            RecordedDose(administeredAt: $0.attendedAt, recordedByName: $0.recordedByName)
        }
    }

    /// Sesión en conflicto con el momento propuesto, si la hay.
    ///
    /// Anotar seis sesiones seguidas tocando seis veces era demasiado fácil, y
    /// una sesión de fisioterapia repetida seis veces en un minuto no es algo
    /// que pueda haber pasado.
    func conflictingSession(for proposedDate: Date) -> RecordedDose? {
        DoseDuplicationCheck.conflictingDose(for: proposedDate, among: recordedSessions)
    }
}

extension TreatmentSession: HealthTimelineItem {
    var timelineRecordedAt: Date { createdAt }
    var timelineDate: Date { attendedAt }
    var timelineTitle: String { treatment?.name ?? String(localized: "Tratamiento") }
    var timelineCategory: HealthCategory {
        treatment?.isPreventive == true ? .preventive : .treatment
    }

    /// El estado es el del tratamiento, no el de la sesión: una sesión pasó.
    var timelineStatus: (any StatusPresentable)? { nil }
}

extension Treatment: HealthTimelineItem {
    var timelineRecordedAt: Date { createdAt }
    var timelineDate: Date { startDate }
    var timelineTitle: String { name }
    var timelineCategory: HealthCategory { isPreventive ? .preventive : .treatment }
    var timelineStatus: (any StatusPresentable)? { status() }
}

@Model
final class Vaccination {
    var id: UUID = UUID()
    var name: String = ""
    var date: Date = Date()
    var nextDueDate: Date?
    var notes: String?
    var reminderEnabled: Bool = true
    var createdAt: Date = Date()

    var companion: Companion?
    var professional: Professional?

    init(name: String = "", date: Date = Date(), nextDueDate: Date? = nil) {
        self.name = name
        self.date = date
        self.nextDueDate = nextDueDate
    }
}

extension Vaccination: HealthTimelineItem {
    var timelineRecordedAt: Date { createdAt }
    var timelineDate: Date { date }
    var timelineTitle: String { name }
    var timelineCategory: HealthCategory { .vaccination }
}
