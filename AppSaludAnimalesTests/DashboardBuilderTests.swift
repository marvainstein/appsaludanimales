import Foundation
import SwiftData
import Testing

@testable import AppSaludAnimales

struct DashboardBuilderTests {
    private let today = Date.test(2024, 5, 20, hour: 9)

    /// El contenedor y el contexto viven mientras dura la prueba: un compañero
    /// cuyo contexto ya se liberó deja de ser utilizable.
    private let container: ModelContainer
    private let context: ModelContext

    init() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    @Test
    func losTurnosDeHoyAparecenEnHoy() throws {
        let companion = try makeCompanion()
        companion.appointments.append(
            Appointment(title: "Control anual", date: .test(2024, 5, 20, hour: 16))
        )

        let snapshot = DashboardBuilder.snapshot(for: companion, on: today, calendar: .test)

        #expect(snapshot.today.map(\.title) == ["Control anual"])
    }

    @Test
    func losTurnosDeOtroDiaNoAparecenEnHoy() throws {
        let companion = try makeCompanion()
        companion.appointments.append(
            Appointment(title: "Control anual", date: .test(2024, 5, 27, hour: 16))
        )

        let snapshot = DashboardBuilder.snapshot(for: companion, on: today, calendar: .test)

        #expect(snapshot.today.isEmpty)
        #expect(snapshot.upcoming.map(\.title) == ["Control anual"])
    }

    @Test
    func laProximaVacunaApareceEnProximamente() throws {
        let companion = try makeCompanion()
        companion.vaccinations.append(
            Vaccination(
                name: "Quíntuple",
                date: .test(2023, 5, 30),
                nextDueDate: .test(2024, 5, 30)
            )
        )

        let snapshot = DashboardBuilder.snapshot(for: companion, on: today, calendar: .test)

        #expect(snapshot.upcoming.map(\.title) == ["Quíntuple"])
    }

    @Test
    func loQueCaeFueraDeLosTreintaDiasNoAparece() throws {
        let companion = try makeCompanion()
        companion.appointments.append(
            Appointment(title: "Control lejano", date: .test(2024, 8, 20, hour: 16))
        )

        let snapshot = DashboardBuilder.snapshot(for: companion, on: today, calendar: .test)

        #expect(snapshot.upcoming.isEmpty)
    }

    @Test
    func elCumpleaniosApareceEnProximamente() throws {
        let companion = try makeCompanion(
            birthDate: .test(2020, 6, 1),
            precision: .exact
        )

        let snapshot = DashboardBuilder.snapshot(for: companion, on: today, calendar: .test)

        #expect(snapshot.upcoming.contains { $0.title.contains("Cumpleaños") })
    }

    @Test
    func elEstadoActualMuestraLoQueEstaEnCurso() throws {
        let companion = try makeCompanion()
        companion.medications.append(
            Medication(name: "Gabapentina", startDate: .test(2024, 5, 1))
        )
        companion.treatments.append(
            Treatment(name: "Fisioterapia", startDate: .test(2024, 4, 1))
        )

        let snapshot = DashboardBuilder.snapshot(for: companion, on: today, calendar: .test)

        #expect(snapshot.currentStatus.map(\.title) == ["Gabapentina", "Fisioterapia"])
        #expect(snapshot.currentStatus.allSatisfy { $0.badge?.label == "Activo" })
    }

    @Test
    func unEpisodioResueltoDejaDeEstarEnEstadoActual() throws {
        let companion = try makeCompanion()
        let episode = HealthEpisode(symptom: "Vómitos", date: .test(2024, 5, 10))
        companion.episodes.append(episode)

        #expect(
            DashboardBuilder.snapshot(for: companion, on: today, calendar: .test)
                .currentStatus.map(\.title) == ["Vómitos"]
        )

        episode.status = .resolved

        #expect(
            DashboardBuilder.snapshot(for: companion, on: today, calendar: .test)
                .currentStatus.isEmpty
        )
    }

    @Test
    func laActividadRecienteSeLimitaACincoEventos() throws {
        let companion = try makeCompanion()
        for day in 1...7 {
            companion.notes.append(
                CompanionNote(text: "Nota \(day)", date: .test(2024, 5, day))
            )
        }

        let snapshot = DashboardBuilder.snapshot(for: companion, on: today, calendar: .test)

        #expect(snapshot.recentActivity.count == DashboardBuilder.recentActivityLimit)
        #expect(snapshot.recentActivity.first?.title == "Nota 7")
    }

    /// El dashboard tiene que responder "qué pasa en esta fecha", no "qué pasa
    /// ahora mismo": si alguna sección mira el reloj en vez de la fecha que se
    /// le pasa, deja de ser consistente consigo misma.
    @Test
    func todasLasSeccionesSeEvaluanEnLaFechaDeReferencia() throws {
        let companion = try makeCompanion()
        companion.medications.append(
            Medication(
                name: "Amoxicilina",
                startDate: .test(2024, 5, 1),
                endDate: .test(2024, 5, 15)
            )
        )

        let duranteElTratamiento = DashboardBuilder.snapshot(
            for: companion,
            on: .test(2024, 5, 10),
            calendar: .test
        )
        #expect(duranteElTratamiento.currentStatus.map(\.title) == ["Amoxicilina"])
        #expect(duranteElTratamiento.upcoming.map(\.title) == ["Amoxicilina"])

        let despues = DashboardBuilder.snapshot(for: companion, on: today, calendar: .test)
        #expect(despues.currentStatus.isEmpty)
        #expect(despues.upcoming.isEmpty)
    }

    @Test
    func unCompanieroReciencreadoNoTieneNadaQueMostrar() throws {
        let companion = try makeCompanion()

        #expect(DashboardBuilder.snapshot(for: companion, on: today, calendar: .test).isEmpty)
    }

    private func makeCompanion(
        birthDate: Date? = nil,
        precision: BirthDatePrecision = .unknown
    ) throws -> Companion {
        let companion = Companion(
            name: "Luli",
            species: .dog,
            birthDate: birthDate,
            birthDatePrecision: precision
        )
        context.insert(companion)
        return companion
    }
}
