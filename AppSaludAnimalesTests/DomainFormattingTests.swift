import Foundation
import Testing

@testable import AppSaludAnimales

struct BirthDatePrecisionTests {
    @Test
    func laFechaExactaSeGuardaTalCual() {
        let date = Date.test(2020, 3, 15)

        #expect(BirthDatePrecision.exact.normalized(date, calendar: .test) == date)
    }

    @Test
    func conMesYAnioSeGuardaElDiaUno() throws {
        let normalized = try #require(
            BirthDatePrecision.monthAndYear.normalized(.test(2020, 3, 15), calendar: .test)
        )
        let components = Calendar.test.dateComponents([.year, .month, .day], from: normalized)

        #expect(components.year == 2020)
        #expect(components.month == 3)
        #expect(components.day == 1)
    }

    @Test
    func conSoloElAnioSeGuardaElPrimeroDeEnero() throws {
        let normalized = try #require(
            BirthDatePrecision.yearOnly.normalized(.test(2020, 3, 15), calendar: .test)
        )
        let components = Calendar.test.dateComponents([.year, .month, .day], from: normalized)

        #expect(components.year == 2020)
        #expect(components.month == 1)
        #expect(components.day == 1)
    }

    @Test
    func sinFechaConocidaNoSeGuardaNada() {
        #expect(BirthDatePrecision.unknown.normalized(.test(2020, 3, 15), calendar: .test) == nil)
    }

    @Test(arguments: BirthDatePrecision.allCases)
    func todaLaPrecisionSalvoLaExactaSeComunicaComoAproximada(precision: BirthDatePrecision) {
        #expect(precision.isApproximate == (precision != .exact))
        #expect(!precision.label.isEmpty)
    }
}

struct DateDescriptionTests {
    private let today = Date.test(2024, 5, 20, hour: 9)

    @Test
    func describeElDiaDeHoy() {
        let text = DateDescription.relative(
            .test(2024, 5, 20, hour: 18),
            from: today,
            calendar: .test
        )

        #expect(text == "Hoy")
    }

    @Test
    func describeManiana() {
        let text = DateDescription.relative(.test(2024, 5, 21), from: today, calendar: .test)

        #expect(text == "Mañana")
    }

    @Test
    func describeAyer() {
        let text = DateDescription.relative(.test(2024, 5, 19), from: today, calendar: .test)

        #expect(text == "Ayer")
    }

    @Test
    func cuentaLosDiasDentroDeLaSemana() {
        let text = DateDescription.relative(.test(2024, 5, 25), from: today, calendar: .test)

        #expect(text == "En 5 días")
    }

    @Test
    func cuentaLosDiasHaciaAtras() {
        let text = DateDescription.relative(.test(2024, 5, 16), from: today, calendar: .test)

        #expect(text == "Hace 4 días")
    }

    @Test
    func masAllaDeLaSemanaUsaLaFecha() {
        let text = DateDescription.relative(.test(2024, 6, 20), from: today, calendar: .test)

        #expect(text != "Hoy")
        #expect(text.contains("20"))
    }
}
