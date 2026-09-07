import Foundation
import Testing

@testable import AppSaludAnimales

struct CompanionAgeTests {
    @Test
    func calculaAniosYMesesConFechaExacta() {
        let age = CompanionAgeCalculator.age(
            birthDate: .test(2020, 3, 15),
            precision: .exact,
            on: .test(2024, 5, 20),
            calendar: .test
        )

        #expect(age?.years == 4)
        #expect(age?.months == 2)
        #expect(age?.isApproximate == false)
    }

    @Test
    func marcaLaEdadComoAproximadaCuandoSoloSeConoceElAnio() {
        let age = CompanionAgeCalculator.age(
            birthDate: .test(2021, 1, 1),
            precision: .yearOnly,
            on: .test(2024, 1, 1),
            calendar: .test
        )

        #expect(age?.isApproximate == true)
        #expect(age?.formatted == "Aproximadamente 3 años")
    }

    @Test
    func noDevuelveEdadCuandoNoSeConoceLaFecha() {
        let age = CompanionAgeCalculator.age(
            birthDate: nil,
            precision: .unknown,
            on: .test(2024, 1, 1),
            calendar: .test
        )

        #expect(age == nil)
    }

    @Test
    func noDevuelveEdadConFechaFutura() {
        let age = CompanionAgeCalculator.age(
            birthDate: .test(2030, 1, 1),
            precision: .exact,
            on: .test(2024, 1, 1),
            calendar: .test
        )

        #expect(age == nil)
    }

    @Test
    func describeCachorrosEnMeses() {
        let age = CompanionAgeCalculator.age(
            birthDate: .test(2023, 9, 10),
            precision: .exact,
            on: .test(2024, 2, 10),
            calendar: .test
        )

        #expect(age?.years == 0)
        #expect(age?.formatted == "5 meses")
    }

    @Test
    func usaSingularConUnSoloAnio() {
        let age = CompanionAge(years: 1, months: 1, isApproximate: false)

        #expect(age.formatted == "1 año y 1 mes")
    }

    @Test
    func calculaElProximoCumpleanios() throws {
        let birthday = CompanionAgeCalculator.nextBirthday(
            birthDate: .test(2020, 6, 30),
            on: .test(2024, 5, 20),
            calendar: .test
        )

        let components = Calendar.test.dateComponents([.year, .month, .day], from: try #require(birthday))
        #expect(components.month == 6)
        #expect(components.day == 30)
        #expect(components.year == 2024)
    }
}

extension Calendar {
    static var test: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }
}

extension Date {
    static func test(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, minute: Int = 0) -> Date {
        Calendar.test.date(
            from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        ) ?? .distantPast
    }
}
