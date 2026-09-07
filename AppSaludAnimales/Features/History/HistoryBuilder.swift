import Foundation

/// Referencia al registro real detrás de una línea del historial, para poder
/// abrirlo, cambiarle el estado o eliminarlo.
enum HealthRecordReference {
    case medication(Medication)
    case treatment(Treatment)
    case vaccination(Vaccination)
    case episode(HealthEpisode)
    case measurement(HealthMeasurement)
    case appointment(Appointment)
    case document(HealthDocument)
    case note(CompanionNote)
}

struct HistoryEntry: Identifiable {
    let id: UUID
    let title: String
    let detail: String?
    let date: Date
    let category: HealthCategory
    let badge: StatusBadge?
    let reference: HealthRecordReference
}

/// Un tramo del historial. Se agrupa por mes porque es como la gente recuerda:
/// "eso fue en mayo", no "eso fue hace 47 días".
struct HistorySection: Identifiable {
    let id: String
    let title: String
    let entries: [HistoryEntry]
}

enum HistoryBuilder {
    /// Todo lo registrado, de lo más nuevo a lo más viejo.
    ///
    /// Un conjunto de categorías vacío significa "todo": es más simple que
    /// mantener seleccionadas todas las categorías por defecto y sincronizarlas
    /// cada vez que aparece una nueva.
    static func entries(
        for companion: Companion,
        categories: Set<HealthCategory> = []
    ) -> [HistoryEntry] {
        var entries: [HistoryEntry] = []

        entries += companion.medications.map { medication in
            HistoryEntry(
                id: medication.id,
                title: medication.name,
                detail: medication.dose,
                date: medication.startDate,
                category: .medication,
                badge: medication.status().badge,
                reference: .medication(medication)
            )
        }

        entries += companion.treatments.map { treatment in
            HistoryEntry(
                id: treatment.id,
                title: treatment.name,
                detail: treatment.category,
                date: treatment.startDate,
                category: treatment.isPreventive ? .preventive : .treatment,
                badge: treatment.status().badge,
                reference: .treatment(treatment)
            )
        }

        entries += companion.vaccinations.map { vaccination in
            HistoryEntry(
                id: vaccination.id,
                title: vaccination.name,
                detail: vaccination.notes,
                date: vaccination.date,
                category: .vaccination,
                badge: nil,
                reference: .vaccination(vaccination)
            )
        }

        entries += companion.episodes.map { episode in
            HistoryEntry(
                id: episode.id,
                title: episode.symptom,
                detail: episode.episodeDescription ?? episode.intensityLabel,
                date: episode.date,
                category: .episode,
                badge: episode.status.badge,
                reference: .episode(episode)
            )
        }

        entries += companion.measurements.map { measurement in
            HistoryEntry(
                id: measurement.id,
                title: measurement.formattedValue,
                detail: measurement.kind.label,
                date: measurement.date,
                category: .measurement,
                badge: nil,
                reference: .measurement(measurement)
            )
        }

        entries += companion.appointments.map { appointment in
            HistoryEntry(
                id: appointment.id,
                title: appointment.title,
                detail: appointment.place,
                date: appointment.date,
                category: .appointment,
                badge: nil,
                reference: .appointment(appointment)
            )
        }

        entries += companion.documents.map { document in
            HistoryEntry(
                id: document.id,
                title: document.title,
                detail: document.category,
                date: document.date,
                category: .document,
                badge: nil,
                reference: .document(document)
            )
        }

        entries += companion.notes.map { note in
            HistoryEntry(
                id: note.id,
                title: note.text,
                detail: nil,
                date: note.date,
                category: .note,
                badge: nil,
                reference: .note(note)
            )
        }

        return entries
            .filter { categories.isEmpty || categories.contains($0.category) }
            .sorted { $0.date > $1.date }
    }

    static func sections(
        for companion: Companion,
        categories: Set<HealthCategory> = [],
        calendar: Calendar = .current
    ) -> [HistorySection] {
        let grouped = Dictionary(grouping: entries(for: companion, categories: categories)) { entry in
            calendar.dateComponents([.year, .month], from: entry.date)
        }

        return grouped
            .compactMap { components, entries -> HistorySection? in
                guard
                    let year = components.year,
                    let month = components.month,
                    let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1))
                else {
                    return nil
                }

                return HistorySection(
                    id: String(format: "%04d-%02d", year, month),
                    title: monthTitle(for: firstDay),
                    entries: entries.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.id > $1.id }
    }

    /// Solo las categorías que tienen algo registrado: un filtro que no filtra
    /// nada es ruido en la pantalla.
    static func availableCategories(for companion: Companion) -> [HealthCategory] {
        let present = Set(entries(for: companion).map(\.category))
        return HealthCategory.allCases.filter(present.contains)
    }

    private static func monthTitle(for date: Date) -> String {
        let title = date.formatted(.dateTime.month(.wide).year())
        return title.prefix(1).uppercased() + title.dropFirst()
    }
}
