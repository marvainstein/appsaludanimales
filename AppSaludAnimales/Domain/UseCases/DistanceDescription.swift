import Foundation

/// Distancias dichas como las diría una persona.
///
/// "A 340 metros" es precisión falsa: nadie camina en línea recta, y el número
/// exacto no cambia ninguna decisión. Se redondea a la banda de 50 metros, y
/// arriba del kilómetro se pasa a kilómetros con un decimal.
enum DistanceDescription {
    static func short(meters: Double) -> String {
        // Se redondea primero y se elige la unidad después: si no, 975 metros
        // quedaban dichos como "a 1000 m" en vez de "a 1 km".
        let rounded = max(50, (meters / 50).rounded() * 50)

        guard rounded >= 1000 else {
            return String(localized: "a \(Int(rounded)) m")
        }

        let kilometers = (rounded / 1000).formatted(.number.precision(.fractionLength(1)))
        return String(localized: "a \(kilometers) km")
    }
}
