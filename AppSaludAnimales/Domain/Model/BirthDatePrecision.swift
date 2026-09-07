import Foundation

/// Precisión con la que se conoce la fecha de nacimiento de un compañero.
///
/// Muchos compañeros son adoptados y no tienen fecha exacta conocida. En vez de
/// una fecha más un interruptor de "aproximada", la precisión es parte del dato:
/// una sola fuente de verdad de la que se derivan la edad y el cumpleaños.
enum BirthDatePrecision: String, Codable, CaseIterable, Sendable {
    case exact
    case monthAndYear
    case yearOnly
    case unknown

    var label: String {
        switch self {
        case .exact:
            String(localized: "Fecha exacta")
        case .monthAndYear:
            String(localized: "Mes y año conocidos")
        case .yearOnly:
            String(localized: "Solo el año")
        case .unknown:
            String(localized: "No se conoce")
        }
    }

    /// Indica si la edad derivada debe comunicarse como estimada.
    var isApproximate: Bool {
        self != .exact
    }

    /// Texto de ayuda en el formulario, para que se entienda qué se va a guardar.
    var explanation: String? {
        switch self {
        case .exact:
            nil
        case .monthAndYear:
            String(localized: "Se guarda el mes y el año. La edad se muestra como aproximada.")
        case .yearOnly:
            String(localized: "Se guarda solo el año. La edad se muestra como aproximada.")
        case .unknown:
            String(localized: "Podés completarla más adelante, cuando quieras.")
        }
    }

    /// Ajusta la fecha a lo que de verdad se conoce: con mes y año se guarda el
    /// día 1, y con solo el año, el 1 de enero. Así el dato almacenado no
    /// aparenta más precisión de la que tiene.
    func normalized(_ date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .exact:
            date
        case .monthAndYear:
            calendar.date(from: DateComponents(
                year: calendar.component(.year, from: date),
                month: calendar.component(.month, from: date),
                day: 1
            ))
        case .yearOnly:
            calendar.date(from: DateComponents(
                year: calendar.component(.year, from: date),
                month: 1,
                day: 1
            ))
        case .unknown:
            nil
        }
    }
}
