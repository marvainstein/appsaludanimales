import Foundation
import SwiftData
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

/// Lo que pasa cuando un compañero ya no está.
///
/// Es la parte de la app que menos se va a usar y la que peor se sentiría si
/// estuviera mal hecha.
struct FarewellTests {
    @Test("La edad deja de correr el día que dejó de estar")
    func laEdadSeDetiene() {
        let companion = Companion(
            name: "Luli",
            species: .dog,
            birthDate: .test(2015, 3, 15),
            birthDatePrecision: .exact
        )
        companion.farewellDate = .test(2025, 11, 12)

        let age = companion.age

        #expect(age?.years == 10, "Tenía diez años cuando dejó de estar, y ahí se queda")
        #expect(companion.isPresent == false)
    }

    @Test("No se anuncia un cumpleaños que ya no va a llegar")
    func noHayProximoCumpleanios() {
        let companion = Companion(
            name: "Luli",
            species: .dog,
            birthDate: .test(2015, 3, 15),
            birthDatePrecision: .exact
        )

        #expect(companion.nextBirthday != nil)

        companion.farewellDate = .test(2025, 11, 12)

        #expect(companion.nextBirthday == nil)
    }

    @Test("Los avisos dejan de pedir cosas por quien ya no está")
    func losAvisosSeApagan() {
        let present = Companion(name: "Primavera", species: .dog)
        let medication = Medication(name: "Meloxicam", startDate: .test(2025, 1, 1))
        medication.timesOfDay = [.morning]
        medication.reminderEnabled = true
        present.medications.append(medication)

        let gone = Companion(name: "Luli", species: .dog)
        let otherMedication = Medication(name: "Fenobarbital", startDate: .test(2025, 1, 1))
        otherMedication.timesOfDay = [.morning]
        otherMedication.reminderEnabled = true
        gone.medications.append(otherMedication)
        gone.farewellDate = .test(2025, 11, 12)

        let plan = ReminderPlanBuilder.plan(
            for: [present, gone].filter(\.isPresent),
            on: .test(2026, 1, 1)
        )

        #expect(plan.isEmpty == false)
        #expect(
            plan.allSatisfy { !$0.title.contains("Fenobarbital") && !$0.body.contains("Fenobarbital") },
            "Un aviso de medicación para quien ya no está es lo peor que podría hacer esta app"
        )
    }

    @Test("Nada se borra: la historia queda entera")
    func laHistoriaQuedaEntera() throws {
        let container = try ModelContainerFactory.makeContainer(inMemory: true)
        let context = ModelContext(container)

        let companion = Companion(name: "Luli", species: .dog)
        companion.episodes.append(HealthEpisode(symptom: "Convulsión", date: .test(2025, 6, 1)))
        companion.measurements.append(HealthMeasurement(value: 24.3, unit: "kg", date: .test(2025, 6, 1)))
        context.insert(companion)
        try context.save()

        companion.farewellDate = .test(2025, 11, 12)
        try context.save()

        let stored = try #require(try context.fetch(FetchDescriptor<Companion>()).first)

        #expect(stored.episodes.count == 1)
        #expect(stored.measurements.count == 1)
        #expect(stored.farewellDate != nil)
    }
}
