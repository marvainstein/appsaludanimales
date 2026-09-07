import Foundation
import SwiftData

/// Episodio de salud: vómitos, tos, dolor, cambios de comportamiento.
///
/// Solo `symptom` y `date` son necesarios para guardar. Todo lo demás se puede
/// completar después: en una sala de espera nadie llena un formulario largo.
@Model
final class HealthEpisode {
    var id: UUID = UUID()
    var symptom: String = ""
    var episodeDescription: String?
    var date: Date = Date()
    var durationDescription: String?

    /// Intensidad de 1 a 5, opcional. Se muestra siempre con texto además de
    /// cualquier representación visual.
    var intensity: Int?
    var statusRawValue: String = EpisodeStatus.active.rawValue
    var resolvedAt: Date?
    var notes: String?
    var createdAt: Date = Date()

    var companion: Companion?

    @Relationship(deleteRule: .cascade, inverse: \HealthDocument.episode)
    var documents: [HealthDocument] = []

    init(
        symptom: String = "",
        date: Date = Date(),
        episodeDescription: String? = nil,
        status: EpisodeStatus = .active
    ) {
        self.symptom = symptom
        self.date = date
        self.episodeDescription = episodeDescription
        self.statusRawValue = status.rawValue
    }
}

extension HealthEpisode {
    var status: EpisodeStatus {
        get { EpisodeStatus(rawValue: statusRawValue) ?? .active }
        set {
            statusRawValue = newValue.rawValue
            resolvedAt = newValue == .resolved ? (resolvedAt ?? Date()) : nil
        }
    }

    var intensityLabel: String? {
        guard let intensity else { return nil }
        return String(localized: "Intensidad \(intensity) de 5")
    }
}

extension HealthEpisode: HealthTimelineItem {
    var timelineDate: Date { date }
    var timelineTitle: String { symptom }
    var timelineCategory: HealthCategory { .episode }
    var timelineStatus: (any StatusPresentable)? { status }
}
