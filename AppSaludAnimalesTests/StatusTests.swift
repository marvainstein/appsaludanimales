import Foundation
import Testing

@testable import AppSaludAnimales

struct StatusTests {
    /// Criterio de accesibilidad del producto: ningún estado se comunica solo
    /// con color, así que todos deben tener texto e ícono.
    @Test(arguments: ActivityStatus.allCases)
    func cadaEstadoDeActividadTieneTextoEIcono(status: ActivityStatus) {
        #expect(!status.label.isEmpty)
        #expect(!status.symbolName.isEmpty)
    }

    @Test(arguments: EpisodeStatus.allCases)
    func cadaEstadoDeEpisodioTieneTextoEIcono(status: EpisodeStatus) {
        #expect(!status.label.isEmpty)
        #expect(!status.symbolName.isEmpty)
    }

    @Test
    func unaMedicacionSinFechaDeFinSigueActiva() {
        let status = MedicationStatusResolver.status(
            startDate: .test(2024, 1, 1),
            endDate: nil,
            isSuspended: false,
            on: .test(2024, 5, 20)
        )

        #expect(status == .active)
    }

    @Test
    func unaMedicacionConFechaDeFinPasadaEstaFinalizada() {
        let status = MedicationStatusResolver.status(
            startDate: .test(2024, 1, 1),
            endDate: .test(2024, 3, 1),
            isSuspended: false,
            on: .test(2024, 5, 20)
        )

        #expect(status == .finished)
    }

    @Test
    func laSuspensionTienePrioridadSobreLasFechas() {
        let status = MedicationStatusResolver.status(
            startDate: .test(2024, 1, 1),
            endDate: nil,
            isSuspended: true,
            on: .test(2024, 5, 20)
        )

        #expect(status == .suspended)
    }

    @Test
    func resolverUnEpisodioRegistraCuandoSeResolvio() {
        let episode = HealthEpisode(symptom: "Vómitos", date: .test(2024, 5, 18))
        #expect(episode.resolvedAt == nil)

        episode.status = .resolved
        #expect(episode.resolvedAt != nil)

        episode.status = .monitoring
        #expect(episode.resolvedAt == nil)
    }
}
