import Foundation

/// Una línea del dashboard. Lleva su propio ícono y su propio estado en texto,
/// para que ninguna sección dependa del color para comunicar qué pasa.
struct DashboardItem: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var detail: String?
    var symbolName: String
    var date: Date?
    var badge: StatusBadge?
}

struct DashboardSnapshot: Equatable {
    var today: [DashboardItem] = []
    var upcoming: [DashboardItem] = []
    var currentStatus: [DashboardItem] = []
    var recentActivity: [DashboardItem] = []

    var isEmpty: Bool {
        today.isEmpty && upcoming.isEmpty && currentStatus.isEmpty && recentActivity.isEmpty
    }
}

/// Arma las cuatro secciones del dashboard a partir de lo registrado.
///
/// Vive fuera de la vista para poder probarlo sin interfaz: qué aparece hoy y
/// qué aparece próximamente es una regla de producto, no un detalle de dibujo.
enum DashboardBuilder {
    /// Ventana de "próximamente". Más de un mes deja de ser una respuesta a
    /// "qué viene después" y se convierte en una lista.
    static let upcomingWindowInDays = 30

    /// Cantidad de eventos recientes. La actividad completa vive en el historial.
    static let recentActivityLimit = 5

    static func snapshot(
        for companion: Companion,
        on referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> DashboardSnapshot {
        DashboardSnapshot(
            today: todayItems(for: companion, on: referenceDate, calendar: calendar),
            upcoming: upcomingItems(for: companion, on: referenceDate, calendar: calendar),
            currentStatus: currentStatusItems(for: companion, on: referenceDate),
            recentActivity: recentActivityItems(for: companion, on: referenceDate)
        )
    }

    // MARK: - Hoy

    private static func todayItems(
        for companion: Companion,
        on referenceDate: Date,
        calendar: Calendar
    ) -> [DashboardItem] {
        let appointments = companion.appointments
            .filter { calendar.isDate($0.date, inSameDayAs: referenceDate) }
            .sorted { $0.date < $1.date }
            .map { appointment in
                DashboardItem(
                    title: appointment.title,
                    detail: appointment.place,
                    symbolName: HealthCategory.appointment.symbolName,
                    date: appointment.date
                )
            }

        let episodes = companion.episodes
            .filter { calendar.isDate($0.date, inSameDayAs: referenceDate) }
            .sorted { $0.date > $1.date }
            .map { episode in
                DashboardItem(
                    title: episode.symptom,
                    detail: episode.episodeDescription,
                    symbolName: HealthCategory.episode.symbolName,
                    date: episode.date,
                    badge: episode.status.badge
                )
            }

        return appointments + episodes
    }

    // MARK: - Próximamente

    private static func upcomingItems(
        for companion: Companion,
        on referenceDate: Date,
        calendar: Calendar
    ) -> [DashboardItem] {
        guard let windowEnd = calendar.date(
            byAdding: .day,
            value: upcomingWindowInDays,
            to: referenceDate
        ) else {
            return []
        }

        func isUpcoming(_ date: Date) -> Bool {
            date > referenceDate
                && date <= windowEnd
                && !calendar.isDate(date, inSameDayAs: referenceDate)
        }

        var items: [DashboardItem] = []

        items += companion.appointments
            .filter { isUpcoming($0.date) }
            .map { appointment in
                DashboardItem(
                    title: appointment.title,
                    detail: appointment.place,
                    symbolName: HealthCategory.appointment.symbolName,
                    date: appointment.date
                )
            }

        items += companion.vaccinations
            .compactMap { vaccination -> DashboardItem? in
                guard let nextDueDate = vaccination.nextDueDate, isUpcoming(nextDueDate) else {
                    return nil
                }

                return DashboardItem(
                    title: vaccination.name,
                    detail: String(localized: "Próxima aplicación"),
                    symbolName: HealthCategory.vaccination.symbolName,
                    date: nextDueDate
                )
            }

        items += companion.treatments
            .compactMap { treatment -> DashboardItem? in
                guard let endDate = treatment.endDate, isUpcoming(endDate) else { return nil }

                return DashboardItem(
                    title: treatment.name,
                    detail: String(localized: "Finaliza el tratamiento"),
                    symbolName: HealthCategory.treatment.symbolName,
                    date: endDate
                )
            }

        items += companion.medications
            .compactMap { medication -> DashboardItem? in
                guard let endDate = medication.endDate, isUpcoming(endDate) else { return nil }

                return DashboardItem(
                    title: medication.name,
                    detail: String(localized: "Última toma"),
                    symbolName: HealthCategory.medication.symbolName,
                    date: endDate
                )
            }

        let birthday = CompanionAgeCalculator.nextBirthday(
            birthDate: companion.birthDate,
            on: referenceDate,
            calendar: calendar
        )

        if let birthday, isUpcoming(birthday) {
            items.append(
                DashboardItem(
                    title: String(localized: "Cumpleaños de \(companion.displayName)"),
                    detail: nil,
                    symbolName: "birthday.cake",
                    date: birthday
                )
            )
        }

        return items.sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
    }

    // MARK: - Estado actual

    private static func currentStatusItems(
        for companion: Companion,
        on referenceDate: Date
    ) -> [DashboardItem] {
        let medications = companion.activeMedications(on: referenceDate)
            .sorted { $0.startDate > $1.startDate }
            .map { medication in
                DashboardItem(
                    title: medication.name,
                    detail: medication.dose,
                    symbolName: HealthCategory.medication.symbolName,
                    date: medication.startDate,
                    badge: medication.status(on: referenceDate).badge
                )
            }

        let treatments = companion.activeTreatments(on: referenceDate)
            .sorted { $0.startDate > $1.startDate }
            .map { treatment in
                DashboardItem(
                    title: treatment.name,
                    detail: treatment.category,
                    symbolName: HealthCategory.treatment.symbolName,
                    date: treatment.startDate,
                    badge: treatment.status(on: referenceDate).badge
                )
            }

        let episodes = companion.openEpisodes
            .sorted { $0.date > $1.date }
            .map { episode in
                DashboardItem(
                    title: episode.symptom,
                    detail: episode.episodeDescription,
                    symbolName: HealthCategory.episode.symbolName,
                    date: episode.date,
                    badge: episode.status.badge
                )
            }

        return medications + treatments + episodes
    }

    // MARK: - Actividad reciente

    /// Incluye todo lo del día, no solo lo anterior a este instante: algo
    /// registrado hoy más tarde sigue siendo actividad reciente, y así lo recién
    /// anotado nunca queda invisible por unos minutos de diferencia.
    private static func recentActivityItems(
        for companion: Companion,
        on referenceDate: Date
    ) -> [DashboardItem] {
        var timeline: [any HealthTimelineItem] = []
        timeline += companion.medications.map { $0 as any HealthTimelineItem }
        timeline += companion.treatments.map { $0 as any HealthTimelineItem }
        timeline += companion.vaccinations.map { $0 as any HealthTimelineItem }
        timeline += companion.episodes.map { $0 as any HealthTimelineItem }
        timeline += companion.measurements.map { $0 as any HealthTimelineItem }
        timeline += companion.appointments.map { $0 as any HealthTimelineItem }
        timeline += companion.documents.map { $0 as any HealthTimelineItem }
        timeline += companion.notes.map { $0 as any HealthTimelineItem }

        // Por cuándo se anotó y no por cuándo pasó. Un estudio de hace dos años
        // que se carga hoy es actividad de hoy: ordenar por la fecha del estudio
        // lo dejaba afuera de los últimos cinco y daba a entender que no se
        // había guardado.
        return timeline
            .filter { $0.timelineRecordedAt <= referenceDate }
            .sorted { $0.timelineRecordedAt > $1.timelineRecordedAt }
            .prefix(recentActivityLimit)
            .map { item in
                DashboardItem(
                    title: item.timelineTitle,
                    detail: item.timelineCategory.label,
                    symbolName: item.timelineCategory.symbolName,
                    date: item.timelineDate,
                    badge: item.timelineStatus?.badge
                )
            }
    }
}
