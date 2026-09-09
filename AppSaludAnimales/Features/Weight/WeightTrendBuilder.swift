import Foundation

/// Un peso registrado, listo para dibujar y para leer en voz alta.
struct WeightPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let value: Double
    let unit: String

    var formattedValue: String {
        let number = value.formatted(.number.precision(.fractionLength(0...2)))
        return "\(number) \(unit)"
    }
}

/// La evolución del peso a lo largo del tiempo.
struct WeightTrend: Equatable {
    /// Del más viejo al más nuevo, que es como se lee una evolución.
    let points: [WeightPoint]
    let minimum: Double
    let maximum: Double

    var latest: WeightPoint? { points.last }
    var earliest: WeightPoint? { points.first }
    var hasEnoughToDraw: Bool { points.count >= 2 }
}

/// Arma la evolución del peso.
///
/// La app no interpreta lo que ve. Dice cuánto cambió y desde cuándo, que es un
/// hecho; no dice si está bien o mal, que es un diagnóstico y no le corresponde.
/// Un cambio de peso puede ser una dieta que funciona o una enfermedad, y la
/// diferencia la sabe el veterinario, no un teléfono.
enum WeightTrendBuilder {
    static func trend(for companion: Companion) -> WeightTrend {
        let points = companion.measurements
            .filter { $0.kind == .weight }
            .sorted { $0.date < $1.date }
            .map {
                WeightPoint(id: $0.id, date: $0.date, value: $0.value, unit: $0.unit)
            }

        let values = points.map(\.value)

        return WeightTrend(
            points: points,
            minimum: values.min() ?? 0,
            maximum: values.max() ?? 0
        )
    }

    /// Cuánto cambió entre el primero y el último, dicho como un hecho.
    static func changeDescription(for trend: WeightTrend) -> String? {
        guard
            trend.hasEnoughToDraw,
            let first = trend.earliest,
            let last = trend.latest
        else {
            return nil
        }

        let difference = last.value - first.value
        let amount = abs(difference).formatted(.number.precision(.fractionLength(0...2)))
        let since = DateDescription.absolute(first.date)

        // Menos de cien gramos entre dos pesadas es la balanza, no el animal.
        guard abs(difference) >= 0.1 else {
            return String(localized: "Se mantiene en \(last.formattedValue) desde el \(since).")
        }

        return difference > 0
            ? String(localized: "Subió \(amount) \(last.unit) desde el \(since).")
            : String(localized: "Bajó \(amount) \(last.unit) desde el \(since).")
    }

    /// Lo que se lee en voz alta cuando el gráfico no se puede ver.
    ///
    /// Un gráfico que solo existe como dibujo es información que algunas
    /// personas no reciben. Esto no es un texto alternativo de compromiso: es la
    /// misma información, dicha con palabras.
    static func summary(for trend: WeightTrend) -> String {
        guard let last = trend.latest else {
            return String(localized: "Todavía no hay pesos registrados.")
        }

        guard trend.hasEnoughToDraw, let first = trend.earliest else {
            return String(localized: "Un solo peso registrado: \(last.formattedValue), del \(DateDescription.absolute(last.date)).")
        }

        let minimum = trend.minimum.formatted(.number.precision(.fractionLength(0...2)))
        let maximum = trend.maximum.formatted(.number.precision(.fractionLength(0...2)))

        return String(localized: "\(trend.points.count) pesos registrados, del \(DateDescription.absolute(first.date)) al \(DateDescription.absolute(last.date)). El más bajo \(minimum) \(last.unit), el más alto \(maximum) \(last.unit). \(changeDescription(for: trend) ?? "")")
    }

    /// El rango vertical del gráfico, con aire arriba y abajo.
    ///
    /// Sin aire, la línea toca los bordes y una variación mínima parece un
    /// derrumbe. Exagerar un cambio de peso en una app de salud asusta sin
    /// motivo, así que el rango nunca es más ajustado que un kilo.
    static func valueRange(for trend: WeightTrend) -> ClosedRange<Double> {
        guard !trend.points.isEmpty else { return 0...1 }

        let span = max(trend.maximum - trend.minimum, 1)
        let padding = span * 0.2

        return max(0, trend.minimum - padding)...(trend.maximum + padding)
    }
}
