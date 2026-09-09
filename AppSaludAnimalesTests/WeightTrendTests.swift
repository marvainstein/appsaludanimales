import Foundation
import SwiftData
import Testing

@testable import AppSaludAnimales

/// El peso es el dato de salud que más se mira a lo largo del tiempo, y también
/// el más fácil de contar mal. Estas pruebas cuidan las dos cosas: que la
/// evolución esté bien armada, y que la app no diga más de lo que sabe.
struct WeightTrendTests {
    @Test("Los pesos se ordenan del más viejo al más nuevo, como se lee una evolución")
    func ordenaDelMasViejoAlMasNuevo() throws {
        let companion = try companionWithWeights([
            (.test(2025, 6, 1), 24.0),
            (.test(2025, 1, 15), 22.5),
            (.test(2025, 3, 10), 23.2)
        ])

        let trend = WeightTrendBuilder.trend(for: companion)

        #expect(trend.points.map(\.value) == [22.5, 23.2, 24.0])
        #expect(trend.minimum == 22.5)
        #expect(trend.maximum == 24.0)
        #expect(trend.latest?.value == 24.0)
    }

    @Test("Dice cuánto cambió, sin decir si está bien o mal")
    func cuentaElCambioSinInterpretarlo() throws {
        let subiendo = try companionWithWeights([
            (.test(2025, 1, 15), 22.5),
            (.test(2025, 6, 1), 24.0)
        ])

        let description = try #require(
            WeightTrendBuilder.changeDescription(for: WeightTrendBuilder.trend(for: subiendo))
        )

        #expect(description.contains("Subió"))
        #expect(description.contains("1,5") || description.contains("1.5"))

        // La app no diagnostica: nada de "sobrepeso", "bajo peso" ni consejos.
        let forbidden = ["sobrepeso", "bajo peso", "obes", "delgad", "debería", "consultá"]
        for word in forbidden {
            #expect(
                !description.lowercased().contains(word),
                "La app no puede interpretar el peso: apareció “\(word)”"
            )
        }
    }

    @Test("Una diferencia mínima es la balanza, no el animal")
    func noInventaUnCambioQueNoExiste() throws {
        let companion = try companionWithWeights([
            (.test(2025, 1, 15), 24.00),
            (.test(2025, 6, 1), 24.05)
        ])

        let description = try #require(
            WeightTrendBuilder.changeDescription(for: WeightTrendBuilder.trend(for: companion))
        )

        #expect(description.contains("mantiene"))
    }

    @Test("Con un solo peso no hay evolución que dibujar, y se dice igual")
    func conUnSoloPesoNoHayEvolucion() throws {
        let companion = try companionWithWeights([(.test(2025, 6, 1), 24.0)])
        let trend = WeightTrendBuilder.trend(for: companion)

        #expect(!trend.hasEnoughToDraw)
        #expect(WeightTrendBuilder.changeDescription(for: trend) == nil)
        #expect(WeightTrendBuilder.summary(for: trend).contains("24"))
    }

    /// Sin aire, la línea toca los bordes y medio kilo parece un derrumbe.
    @Test("El rango del gráfico nunca exagera una variación chica")
    func elRangoNoExageraLaVariacion() throws {
        let companion = try companionWithWeights([
            (.test(2025, 1, 15), 24.0),
            (.test(2025, 6, 1), 24.2)
        ])

        let range = WeightTrendBuilder.valueRange(for: WeightTrendBuilder.trend(for: companion))

        #expect(
            range.upperBound - range.lowerBound >= 1,
            "Una diferencia de 200 gramos no puede ocupar todo el alto del gráfico"
        )
    }

    @Test("El resumen hablado dice lo mismo que muestra el dibujo")
    func elResumenHabladoNoPierdeInformacion() throws {
        let companion = try companionWithWeights([
            (.test(2025, 1, 15), 22.5),
            (.test(2025, 3, 10), 23.2),
            (.test(2025, 6, 1), 24.0)
        ])

        let summary = WeightTrendBuilder.summary(for: WeightTrendBuilder.trend(for: companion))

        #expect(summary.contains("3"), "Tiene que decir cuántos pesos hay")
        #expect(summary.contains("22,5") || summary.contains("22.5"), "Tiene que decir el más bajo")
        #expect(summary.contains("24"), "Tiene que decir el más alto")
        #expect(summary.contains("Subió"), "Tiene que decir cómo cambió")
    }

    private func companionWithWeights(_ weights: [(Date, Double)]) throws -> Companion {
        let container = try ModelContainerFactory.makeContainer(inMemory: true)
        let context = ModelContext(container)

        let companion = Companion(name: "Luli", species: .dog)
        for (date, value) in weights {
            companion.measurements.append(
                HealthMeasurement(kind: .weight, value: value, unit: "kg", date: date)
            )
        }

        context.insert(companion)
        try context.save()

        return companion
    }
}
