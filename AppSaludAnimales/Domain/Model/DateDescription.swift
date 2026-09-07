import Foundation

/// Fechas contadas como las cuenta una persona: "hoy", "mañana", "en 5 días".
///
/// El dashboard responde "qué viene después", y para eso la distancia importa
/// más que la fecha exacta.
enum DateDescription {
    static func relative(
        _ date: Date,
        from referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let start = calendar.startOfDay(for: referenceDate)
        let target = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: target).day ?? 0

        switch days {
        case 0:
            return String(localized: "Hoy")
        case 1:
            return String(localized: "Mañana")
        case -1:
            return String(localized: "Ayer")
        case 2...7:
            return String(localized: "En \(days) días")
        case -7 ... -2:
            return String(localized: "Hace \(abs(days)) días")
        default:
            return absolute(date, from: referenceDate, calendar: calendar)
        }
    }

    static func absolute(
        _ date: Date,
        from referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let sameYear = calendar.component(.year, from: date)
            == calendar.component(.year, from: referenceDate)

        return sameYear
            ? date.formatted(.dateTime.day().month(.wide))
            : date.formatted(.dateTime.day().month(.wide).year())
    }
}
