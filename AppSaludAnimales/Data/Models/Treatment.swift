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
