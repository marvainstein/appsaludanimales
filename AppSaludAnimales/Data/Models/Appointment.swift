import Foundation
import SwiftData

@Model
final class Appointment {
    var id: UUID = UUID()
    var title: String = ""
    var date: Date = Date()
    var place: String?
    var notes: String?
    var reminderEnabled: Bool = true

    /// Anticipación del recordatorio, en minutos.
    var reminderLeadTimeMinutes: Int = 60 * 24

    /// Identificador del evento exportado al Calendario de Apple, para poder
    /// actualizarlo o quitarlo. La app es la fuente de verdad; el calendario es
    /// un destino de exportación.
    var calendarEventIdentifier: String?
    var createdAt: Date = Date()

    var companion: Companion?
    var professional: Professional?

    @Relationship(deleteRule: .nullify, inverse: \HealthDocument.appointment)
    var documents: [HealthDocument] = []

    init(title: String = "", date: Date = Date(), place: String? = nil) {
        self.title = title
        self.date = date
        self.place = place
    }
}

extension Appointment: HealthTimelineItem {
    var timelineDate: Date { date }
    var timelineTitle: String { title }
    var timelineCategory: HealthCategory { .appointment }
}

/// Documento adjunto: análisis, radiografía, receta, indicación, foto.
@Model
final class HealthDocument {
    var id: UUID = UUID()
    var title: String = ""
    var category: String?
    var date: Date = Date()
    var fileName: String?
    var contentTypeIdentifier: String?
    var notes: String?

    /// Descripción accesible del contenido, para imágenes informativas.
    var accessibilityDescription: String?
    var createdAt: Date = Date()

    @Attribute(.externalStorage)
    var fileData: Data?

    var companion: Companion?
    var episode: HealthEpisode?
    var appointment: Appointment?

    init(title: String = "", category: String? = nil, date: Date = Date()) {
        self.title = title
        self.category = category
        self.date = date
    }
}

extension HealthDocument: HealthTimelineItem {
    var timelineDate: Date { date }
    var timelineTitle: String { title }
    var timelineCategory: HealthCategory { .document }
}

/// Nota libre: la vía de escape del modelo, para lo que no entra en ninguna
/// estructura y aun así la persona quiere recordar.
@Model
final class CompanionNote {
    var id: UUID = UUID()
    var text: String = ""
    var date: Date = Date()
    var createdAt: Date = Date()

    var companion: Companion?

    init(text: String = "", date: Date = Date()) {
        self.text = text
        self.date = date
    }
}

extension CompanionNote: HealthTimelineItem {
    var timelineDate: Date { date }
    var timelineTitle: String { text }
    var timelineCategory: HealthCategory { .note }
}
