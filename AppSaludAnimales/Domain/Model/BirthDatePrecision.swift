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
}
