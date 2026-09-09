import Foundation

/// Los horarios de una medicación.
///
/// La app arrancó pidiendo momentos del día —mañana, mediodía, tarde, noche— y
/// eso resultó ambiguo de una manera que no se arregla: la app decidía por
/// dentro que "mañana" eran las ocho y no se lo decía a nadie. Hacer esa hora
/// configurable tampoco alcanzaba, porque la mañana de alguien puede ser a las
/// siete un día y a las ocho otro, y no se puede vivir reconfigurando.
///
/// Así que se piden horarios y punto. Es lo que dice la receta.
enum MedicationSchedule {
    /// Los horarios de una medicación existente, para editarla.
    ///
    /// Las medicaciones cargadas cuando la app pedía momentos del día se leen
    /// con la hora que la app usaba para cada momento, así nadie pierde lo que
    /// tenía cargado.
    static func times(for medication: Medication?, calendar: Calendar = .current) -> [Date] {
        guard let medication else { return [] }

        if !medication.exactTimes.isEmpty {
            return medication.exactTimes.sorted()
        }

        return medication.timesOfDay
            .compactMap(\.defaultReminderHour)
            .sorted()
            .compactMap { hour in
                calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date())
            }
    }

    /// Qué horario proponer al agregar uno más.
    ///
    /// Ocho de la mañana, ocho de la noche, y del tercero en adelante el
    /// mediodía. Son los repartos habituales de una toma diaria, de dos y de
    /// tres, y proponerlos ahorra el paso más aburrido.
    static func nextSuggestedTime(after times: [Date], calendar: Calendar = .current) -> Date {
        let hour: Int

        switch times.count {
        case 0: hour = 8
        case 1: hour = 20
        case 2: hour = 12
        default: hour = 16
        }

        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }

    /// Cómo se leen los horarios en una pantalla o en el PDF.
    static func description(for medication: Medication) -> String? {
        let times = Self.times(for: medication)

        guard !times.isEmpty else { return nil }

        return times
            .map { $0.formatted(date: .omitted, time: .shortened) }
            .joined(separator: ", ")
    }
}
