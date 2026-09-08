import Foundation
import SwiftData
import Testing

@testable import AppSaludAnimales

struct HealthReportTests {
    private let today = Date.test(2024, 5, 20, hour: 9)
    private let container: ModelContainer
    private let context: ModelContext

    init() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    @Test
    func soloIncluyeLasSeccionesElegidas() throws {
        let companion = try makeCompanion()

        let report = HealthReportBuilder.report(
            for: companion,
            period: .month,
            sections: [.basics],
            on: today,
            calendar: .test
        )

        #expect(report.sections.map(\.title) == [ReportSectionKind.basics.label])
    }

    @Test
    func unaSeccionSinInformacionNoAparece() throws {
        let companion = try makeCompanion()

        let report = HealthReportBuilder.report(
            for: companion,
            period: .month,
            sections: Set(ReportSectionKind.allCases),
            on: today,
            calendar: .test
        )

        #expect(!report.sections.contains { $0.title == ReportSectionKind.criticalHealth.label })
        #expect(!report.sections.contains { $0.title == ReportSectionKind.vaccinations.label })
    }

    @Test
    func elPeriodoRecortaLoQueQuedaAfuera() throws {
        let companion = try makeCompanion()
        companion.episodes.append(HealthEpisode(symptom: "Reciente", date: .test(2024, 5, 15)))
        companion.episodes.append(HealthEpisode(symptom: "Viejo", date: .test(2023, 5, 15)))

        let mes = HealthReportBuilder.report(
            for: companion,
            period: .month,
            sections: [.episodes],
            on: today,
            calendar: .test
        )
        let todo = HealthReportBuilder.report(
            for: companion,
            period: .all,
            sections: [.episodes],
            on: today,
            calendar: .test
        )

        #expect(mes.sections.first?.lines.map(\.text) == ["Reciente"])
        #expect(todo.sections.first?.lines.map(\.text) == ["Reciente", "Viejo"])
    }

    @Test
    func elPesoTraeLaVariacionEnPalabras() throws {
        let companion = try makeCompanion()
        companion.measurements.append(HealthMeasurement(value: 24.3, date: .test(2024, 5, 1)))
        companion.measurements.append(HealthMeasurement(value: 22.8, date: .test(2024, 5, 18)))

        let report = HealthReportBuilder.report(
            for: companion,
            period: .month,
            sections: [.weight],
            on: today,
            calendar: .test
        )

        let firstLine = try #require(report.sections.first?.lines.first)
        #expect(firstLine.text == "Variación en el período")
        #expect(firstLine.detail?.contains("bajó") == true)
    }

    @Test
    func conUnSoloPesoNoHayVariacionQueContar() throws {
        let companion = try makeCompanion()
        companion.measurements.append(HealthMeasurement(value: 24.3, date: .test(2024, 5, 1)))

        let report = HealthReportBuilder.report(
            for: companion,
            period: .month,
            sections: [.weight],
            on: today,
            calendar: .test
        )

        #expect(report.sections.first?.lines.count == 1)
        #expect(report.sections.first?.lines.first?.text != "Variación en el período")
    }

    @Test
    func lasMedicacionesTerminadasNoFiguranComoActuales() throws {
        let companion = try makeCompanion()
        companion.medications.append(
            Medication(name: "Gabapentina", dose: "media pastilla", startDate: .test(2024, 5, 1))
        )
        companion.medications.append(
            Medication(name: "Amoxicilina", startDate: .test(2024, 1, 1), endDate: .test(2024, 2, 1))
        )

        let report = HealthReportBuilder.report(
            for: companion,
            period: .month,
            sections: [.currentCare],
            on: today,
            calendar: .test
        )

        #expect(report.sections.first?.lines.map(\.text) == ["Gabapentina"])
    }

    @Test
    func elResumenGuardaElPeriodoYLaFechaDeGeneracion() throws {
        let companion = try makeCompanion()

        let report = HealthReportBuilder.report(
            for: companion,
            period: .quarter,
            sections: [.basics],
            on: today,
            calendar: .test
        )

        #expect(report.periodDescription == ReportPeriod.quarter.description)
        #expect(report.generatedOn == today)
        #expect(report.companionName == "Luli")
    }

    @Test
    func elPdfSeGeneraConContenido() throws {
        let companion = try makeCompanion()
        companion.episodes.append(HealthEpisode(symptom: "Tos", date: .test(2024, 5, 15)))

        let report = HealthReportBuilder.report(
            for: companion,
            period: .month,
            sections: Set(ReportSectionKind.allCases),
            on: today,
            calendar: .test
        )

        let data = PDFReportRenderer.render(report)

        #expect(data.count > 1_000)
        #expect(data.prefix(4) == Data("%PDF".utf8))
    }

    private func makeCompanion() throws -> Companion {
        let companion = Companion(name: "Luli", species: .dog)
        context.insert(companion)
        return companion
    }
}
