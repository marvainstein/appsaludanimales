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

    /// Intensidad, opcional. Se guarda el valor crudo de `EpisodeIntensity` y se
    /// muestra siempre con texto, nunca solo como una barra o un color.
    var intensityRawValue: Int?
    var statusRawValue: String = EpisodeStatus.active.rawValue
    var resolvedAt: Date?
    var notes: String?
    var createdAt: Date = Date()

    var companion: Companion?

    // Nullify y no cascade: el documento es del compañero, y el episodio es un
    // vínculo de más. Borrar un episodio no puede llevarse puesta una
    // radiografía, que cuesta plata y no se puede repetir.
    @Relationship(deleteRule: .nullify, inverse: \HealthDocument.episode)
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

    var intensity: EpisodeIntensity? {
        get { intensityRawValue.flatMap(EpisodeIntensity.init(rawValue:)) }
        set { intensityRawValue = newValue?.rawValue }
    }

    var intensityLabel: String? {
        guard let intensity else { return nil }
        return String(localized: "Intensidad \(intensity.label.lowercased())")
    }
}

extension HealthEpisode: HealthTimelineItem {
    var timelineDate: Date { date }
    var timelineTitle: String { symptom }
    var timelineCategory: HealthCategory { .episode }
    var timelineStatus: (any StatusPresentable)? { status }
}
