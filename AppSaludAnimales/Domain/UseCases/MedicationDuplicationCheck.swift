import Foundation

/// Reconoce cuándo dos medicaciones son, con toda probabilidad, la misma.
///
/// Igual que con las dosis, esto avisa y no impide: puede haber dos
/// medicaciones con el mismo nombre y distinta dosis, y quien cuida sabe si es
/// el caso. Lo que no debería pasar es cargar la misma sin darse cuenta.
enum MedicationDuplicationCheck {
    static func isSameMedication(_ lhs: String, _ rhs: String) -> Bool {
        normalized(lhs) == normalized(rhs)
    }

    /// El aviso propone la acción que probablemente se quería hacer, en vez de
    /// limitarse a señalar el problema.
    static func warningMessage(for name: String) -> String {
        String(localized: "Ya hay una medicación llamada “\(name)” en curso. Si es la misma, podés registrar una toma en vez de agregarla de nuevo.")
    }

    private static func normalized(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
