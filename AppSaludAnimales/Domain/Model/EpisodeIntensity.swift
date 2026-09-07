import Foundation

/// Intensidad de un episodio, en tres niveles.
///
/// Una escala de uno a cinco suena más precisa, pero quien registra está
/// describiendo lo que ve, no midiendo: tres opciones se eligen de un vistazo y
/// significan lo mismo para cualquiera.
enum EpisodeIntensity: Int, Codable, CaseIterable, Sendable {
    case mild = 1
    case moderate = 2
    case strong = 3

    var label: String {
        switch self {
        case .mild: String(localized: "Leve")
        case .moderate: String(localized: "Moderada")
        case .strong: String(localized: "Fuerte")
        }
    }
}

/// Síntomas que la app ofrece como sugerencia.
///
/// Es una ayuda para escribir más rápido, no una lista cerrada: siempre se puede
/// registrar algo que no esté acá.
enum SymptomSuggestions {
    static let all: [String] = [
        String(localized: "Vómitos"),
        String(localized: "Diarrea"),
        String(localized: "Tos"),
        String(localized: "Decaimiento"),
        String(localized: "Falta de apetito"),
        String(localized: "Dolor"),
        String(localized: "Cambios de comportamiento"),
        String(localized: "Problemas de movilidad"),
        String(localized: "Herida"),
        String(localized: "Convulsiones"),
        String(localized: "Picazón"),
        String(localized: "Dificultad para respirar")
    ]

    /// Sugerencias para lo que se está escribiendo. Sin texto devuelve las más
    /// frecuentes, para que la lista sirva desde el primer momento.
    static func matching(_ text: String, limit: Int = 6) -> [String] {
        let query = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        guard !query.isEmpty else {
            return Array(all.prefix(limit))
        }

        return all
            .filter { suggestion in
                suggestion
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                    .contains(query)
            }
            .prefix(limit)
            .map { $0 }
    }
}
