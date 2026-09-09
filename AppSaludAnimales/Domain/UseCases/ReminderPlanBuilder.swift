import Foundation

enum ReminderCategory: String, Sendable {
    /// Recordatorio de una toma, con la acción de registrarla desde la propia
    /// notificación.
    case medicationDose
    case general
}

struct ReminderRequest: Equatable, Identifiable, Sendable {
    enum Trigger: Equatable, Sendable {
        case daily(hour: Int, minute: Int)
        case at(Date)
    }

    let id: String
    let title: String
    let body: String
    let trigger: Trigger
    let category: ReminderCategory
    let medicationID: UUID?
}

/// Decide qué avisos tiene sentido programar.
///
/// Dos reglas de producto viven acá: el tono —siempre una pregunta abierta,
/// nunca un reproche— y el presupuesto de avisos, porque una app que notifica de
/// más se termina silenciando entera.
enum ReminderPlanBuilder {
    /// iOS conserva como máximo 64 notificaciones pendientes por app. Se deja
    /// margen para no perder las últimas de la lista sin darse cuenta.
    static let maximumReminders = 60

    /// Cuánto antes avisa una vacuna que está por vencer.
    static let vaccinationLeadDays = 1

    static let vaccinationReminderHour = 9

    static func plan(
        for companions: [Companion],
        on referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [ReminderRequest] {
        let dated = companions.flatMap { companion in
            datedReminders(for: companion, on: referenceDate, calendar: calendar)
        }
        .sorted { lhs, rhs in
            triggerDate(lhs) ?? .distantFuture < triggerDate(rhs) ?? .distantFuture
        }

        let daily = companions.flatMap { dailyReminders(for: $0, on: referenceDate) }

        // Lo que tiene fecha va primero: si hay que recortar, se recorta lo que
        // se repite todos los días y vuelve a aparecer mañana.
        return Array((dated + daily).prefix(maximumReminders))
    }

    // MARK: - Con fecha

    private static func datedReminders(
        for companion: Companion,
        on referenceDate: Date,
        calendar: Calendar
    ) -> [ReminderRequest] {
        var requests: [ReminderRequest] = []

        for vaccination in companion.vaccinations where vaccination.reminderEnabled {
            guard
                let dueDate = vaccination.nextDueDate,
                let fireDate = calendar.date(
                    byAdding: .day,
                    value: -vaccinationLeadDays,
                    to: calendar.startOfDay(for: dueDate)
                ),
                let fireDateAtHour = calendar.date(
                    bySettingHour: vaccinationReminderHour,
                    minute: 0,
                    second: 0,
                    of: fireDate
                ),
                fireDateAtHour > referenceDate
            else {
                continue
            }

            requests.append(
                ReminderRequest(
                    id: "vaccination-\(vaccination.id.uuidString)",
                    title: String(localized: "Vacuna de \(companion.displayName)"),
                    body: String(localized: "Mañana toca \(vaccination.name)."),
                    trigger: .at(fireDateAtHour),
                    category: .general,
                    medicationID: nil
                )
            )
        }

        for appointment in companion.appointments where appointment.reminderEnabled {
            guard
                let fireDate = calendar.date(
                    byAdding: .minute,
                    value: -appointment.reminderLeadTimeMinutes,
                    to: appointment.date
                ),
                fireDate > referenceDate
            else {
                continue
            }

            requests.append(
                ReminderRequest(
                    id: "appointment-\(appointment.id.uuidString)",
                    title: String(localized: "Turno de \(companion.displayName)"),
                    // Con la hora adentro: el aviso llega una hora antes, o el
                    // día anterior, y lo primero que se quiere saber es a qué
                    // hora hay que estar ahí.
                    body: String(localized: "\(appointment.title), a las \(ReminderPlanBuilder.time(appointment.date))"),
                    trigger: .at(fireDate),
                    category: .general,
                    medicationID: nil
                )
            )
        }

        return requests
    }

    /// La hora, como se lee de un vistazo en una notificación.
    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Todos los días

    private static func dailyReminders(
        for companion: Companion,
        on referenceDate: Date
    ) -> [ReminderRequest] {
        var requests: [ReminderRequest] = []

        for medication in companion.activeMedications(on: referenceDate) where medication.reminderEnabled {
            for (index, hour) in reminderHours(for: medication).enumerated() {
                requests.append(
                    ReminderRequest(
                        id: "medication-\(medication.id.uuidString)-\(index)",
                        title: String(localized: "Medicación de \(companion.displayName)"),
                        body: String(localized: "¿Le diste \(medication.name)?"),
                        trigger: .daily(hour: hour.hour, minute: hour.minute),
                        category: .medicationDose,
                        medicationID: medication.id
                    )
                )
            }
        }

        return requests
    }

    /// Los horarios exactos mandan; si no hay, se usan las horas de referencia
    /// de cada momento del día.
    private static func reminderHours(
        for medication: Medication,
        calendar: Calendar = .current
    ) -> [(hour: Int, minute: Int)] {
        if !medication.exactTimes.isEmpty {
            return medication.exactTimes
                .map { time in
                    (
                        hour: calendar.component(.hour, from: time),
                        minute: calendar.component(.minute, from: time)
                    )
                }
                .sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
        }

        return medication.timesOfDay
            .compactMap(\.defaultReminderHour)
            .sorted()
            .map { (hour: $0, minute: 0) }
    }

    private static func triggerDate(_ request: ReminderRequest) -> Date? {
        if case let .at(date) = request.trigger { return date }
        return nil
    }
}
