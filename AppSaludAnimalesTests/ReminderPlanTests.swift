import Foundation
import SwiftData
import Testing

@testable import AppSaludAnimales

struct ReminderPlanTests {
    private let today = Date.test(2024, 5, 20, hour: 9)
    private let container: ModelContainer
    private let context: ModelContext

    init() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    @Test
    func armaUnAvisoDiarioPorCadaMomentoDelDia() throws {
        let companion = try makeCompanion()
        let medication = Medication(name: "Gabapentina", startDate: .test(2024, 5, 1))
        medication.timesOfDay = [.morning, .night]
        companion.medications.append(medication)

        let plan = ReminderPlanBuilder.plan(for: [companion], on: today, calendar: .test)

        #expect(plan.count == 2)
        #expect(plan.allSatisfy { $0.category == .medicationDose })
        #expect(plan.map(\.trigger) == [.daily(hour: 8, minute: 0), .daily(hour: 21, minute: 0)])
    }

    @Test
    func segunNecesidadNoAvisa() throws {
        let companion = try makeCompanion()
        let medication = Medication(name: "Analgésico", startDate: .test(2024, 5, 1))
        medication.timesOfDay = [.asNeeded]
        companion.medications.append(medication)

        #expect(ReminderPlanBuilder.plan(for: [companion], on: today, calendar: .test).isEmpty)
    }

    @Test
    func unaMedicacionSinAvisoActivadoNoEntraEnElPlan() throws {
        let companion = try makeCompanion()
        let medication = Medication(name: "Gabapentina", startDate: .test(2024, 5, 1))
        medication.timesOfDay = [.morning]
        medication.reminderEnabled = false
        companion.medications.append(medication)

        #expect(ReminderPlanBuilder.plan(for: [companion], on: today, calendar: .test).isEmpty)
    }

    @Test
    func unaMedicacionTerminadaNoAvisaMas() throws {
        let companion = try makeCompanion()
        let medication = Medication(
            name: "Amoxicilina",
            startDate: .test(2024, 4, 1),
            endDate: .test(2024, 5, 10)
        )
        medication.timesOfDay = [.morning]
        companion.medications.append(medication)

        #expect(ReminderPlanBuilder.plan(for: [companion], on: today, calendar: .test).isEmpty)
    }

    @Test
    func laVacunaAvisaElDiaAnterior() throws {
        let companion = try makeCompanion()
        companion.vaccinations.append(
            Vaccination(
                name: "Quíntuple",
                date: .test(2023, 5, 30),
                nextDueDate: .test(2024, 5, 30)
            )
        )

        let plan = ReminderPlanBuilder.plan(for: [companion], on: today, calendar: .test)

        #expect(plan.count == 1)
        #expect(plan.first?.category == .general)

        if case let .at(date) = try #require(plan.first?.trigger) {
            let components = Calendar.test.dateComponents([.month, .day, .hour], from: date)
            #expect(components.month == 5)
            #expect(components.day == 29)
            #expect(components.hour == ReminderPlanBuilder.vaccinationReminderHour)
        } else {
            Issue.record("El aviso de una vacuna tiene que tener fecha")
        }
    }

    @Test
    func loQueYaPasoNoSeProgramaDeNuevo() throws {
        let companion = try makeCompanion()
        companion.vaccinations.append(
            Vaccination(
                name: "Quíntuple",
                date: .test(2023, 1, 1),
                nextDueDate: .test(2024, 1, 10)
            )
        )
        companion.appointments.append(
            Appointment(title: "Control", date: .test(2024, 1, 15))
        )

        #expect(ReminderPlanBuilder.plan(for: [companion], on: today, calendar: .test).isEmpty)
    }

    @Test
    func elTurnoAvisaConLaAnticipacionConfigurada() throws {
        let companion = try makeCompanion()
        let appointment = Appointment(title: "Control anual", date: .test(2024, 5, 27, hour: 16))
        appointment.reminderLeadTimeMinutes = 60
        companion.appointments.append(appointment)

        let plan = ReminderPlanBuilder.plan(for: [companion], on: today, calendar: .test)

        #expect(plan.first?.body.hasPrefix("Control anual") == true)

        if case let .at(date) = try #require(plan.first?.trigger) {
            #expect(date == .test(2024, 5, 27, hour: 15))
        } else {
            Issue.record("El aviso de un turno tiene que tener fecha")
        }
    }

    @Test
    func noSePasaDelPresupuestoDeAvisos() throws {
        let companion = try makeCompanion()
        for index in 1...40 {
            let medication = Medication(name: "Medicación \(index)", startDate: .test(2024, 5, 1))
            medication.timesOfDay = [.morning, .midday, .night]
            companion.medications.append(medication)
        }

        let plan = ReminderPlanBuilder.plan(for: [companion], on: today, calendar: .test)

        #expect(plan.count == ReminderPlanBuilder.maximumReminders)
    }

    @Test
    func loQueTieneFechaSeConservaAntesQueLoDiario() throws {
        let companion = try makeCompanion()
        companion.appointments.append(
            Appointment(title: "Control", date: .test(2024, 5, 25, hour: 10))
        )
        for index in 1...40 {
            let medication = Medication(name: "Medicación \(index)", startDate: .test(2024, 5, 1))
            medication.timesOfDay = [.morning, .midday, .night]
            companion.medications.append(medication)
        }

        let plan = ReminderPlanBuilder.plan(for: [companion], on: today, calendar: .test)

        #expect(plan.first?.body.hasPrefix("Control") == true)
    }

    @Test
    func cadaAvisoLlevaSuMedicacionParaPoderRegistrarLaToma() throws {
        let companion = try makeCompanion()
        let medication = Medication(name: "Gabapentina", startDate: .test(2024, 5, 1))
        medication.timesOfDay = [.morning]
        companion.medications.append(medication)

        let plan = ReminderPlanBuilder.plan(for: [companion], on: today, calendar: .test)

        #expect(plan.first?.medicationID == medication.id)
    }

    private func makeCompanion() throws -> Companion {
        let companion = Companion(name: "Luli", species: .dog)
        context.insert(companion)
        return companion
    }
}

/// Lo que dice el aviso cuando llega.
struct ReminderMessageTests {
    @Test("El aviso de un turno trae la hora del turno")
    func elTurnoTraeLaHora() {
        let companion = Companion(name: "Luli", species: .dog)
        let appointment = Appointment(title: "Fisio", date: .test(2026, 3, 10, hour: 16, minute: 10))
        appointment.reminderEnabled = true
        appointment.reminderLeadTimeMinutes = 60
        companion.appointments.append(appointment)

        let plan = ReminderPlanBuilder.plan(for: [companion], on: .test(2026, 3, 10, hour: 9))
        let turno = plan.first { $0.title.contains("Turno") }

        #expect(turno != nil)
        // Con la hora escrita como la escribe el sistema. Compararla contra un
        // número fijo ataba la prueba a la zona horaria de quien la corre.
        #expect(
            turno?.body.contains(ReminderPlanBuilder.time(appointment.date)) == true,
            "El aviso llega una hora antes: lo primero que se quiere saber es a qué hora hay que estar"
        )
        #expect(turno?.body.contains("Fisio") == true)
    }
}
