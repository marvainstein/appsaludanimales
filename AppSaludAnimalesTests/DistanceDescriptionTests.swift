import Foundation
import Testing

@testable import AppSaludAnimales

/// Una distancia se dice como la diría una persona, no como la calcula un
/// teléfono.
struct DistanceDescriptionTests {
    @Test("Debajo del kilómetro redondea a bandas de 50 metros")
    func redondeaALaBandaDeCincuenta() {
        #expect(DistanceDescription.short(meters: 340).contains("350"))
        #expect(DistanceDescription.short(meters: 812).contains("800"))
    }

    @Test("Nunca dice que algo está a cero metros")
    func nuncaDiceCero() {
        #expect(DistanceDescription.short(meters: 4).contains("50"))
        #expect(DistanceDescription.short(meters: 0).contains("50"))
    }

    @Test("Arriba del kilómetro pasa a kilómetros con un decimal")
    func arribaDelKilometroCambiaDeUnidad() {
        let far = DistanceDescription.short(meters: 2400)

        #expect(far.contains("km"))
        #expect(far.contains("2,4") || far.contains("2.4"))
    }

    /// Redondear a 1000 metros y después decirlo en metros era el borde feo.
    @Test("Casi un kilómetro se dice en kilómetros, no en mil metros")
    func elBordeDelKilometro() {
        let almost = DistanceDescription.short(meters: 975)

        #expect(almost.contains("km"))
        #expect(!almost.contains("1000"))
    }
}
