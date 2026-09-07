import Foundation

/// Lee el peso tal como lo escribe una persona.
///
/// Acá se escribe "24,3" y en otros lugares "24.3"; los dos son válidos y
/// ninguno debería devolver un error. Un peso vacío o imposible no se guarda,
/// pero tampoco se trata como una falta: el formulario simplemente espera.
enum WeightInputParser {
    /// Peso máximo aceptado en kilogramos. Un perro o un gato no llegan ahí, así
    /// que por encima es casi seguro un error de tipeo.
    static let maximumKilograms: Double = 200

    static func parse(_ text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !normalized.isEmpty, let value = Double(normalized) else { return nil }
        guard value > 0, value <= maximumKilograms else { return nil }

        return value
    }

    /// Mensaje de ayuda cuando lo escrito todavía no es un peso utilizable.
    /// Habla del dato, no de quien lo escribió.
    static func guidance(for text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return nil }
        guard parse(trimmed) == nil else { return nil }

        return String(localized: "Escribí el peso en kilogramos, por ejemplo 24,3.")
    }
}
