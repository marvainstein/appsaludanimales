import Foundation
import SwiftData
import Testing

@testable import AppSaludAnimales

/// Las tomas anotadas tienen que verse.
///
/// La app las guardaba y no las mostraba en ningún lado: la medicación aparecía
/// una sola vez, fechada el día en que se cargó, y cada toma posterior se
/// guardaba sin dejar rastro. La primera persona que lo probó dio la
/// medicación, no vio nada y concluyó que no había funcionado.
struct MedicationDoseTimelineTests {
    private let container: ModelContainer
    private let context: ModelContext

    init() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    @Test
    func laTomaAnotadaApareceEnLaActividadReciente() throws {
        let companion = try makeCompanion()
        let medication = Medication(
            name: "Contal 150",
            dose: "Media pastilla",
            startDate: .test(2024, 10, 9)
        )
        companion.medications.append(medication)
        medication.doses.append(MedicationDose(administeredAt: .test(2026, 9, 10)))

        let snapshot = DashboardBuilder.snapshot(for: companion, on: .test(2026, 9, 10))

        #expect(snapshot.recentActivity.contains { $0.detail == "Toma anotada" })
    }

    /// Dos tomas en el mismo día son dos renglones: si se fusionaran, no habría
    /// forma de saber si se dio la de la noche.
    @Test
    func cadaTomaEsUnRegistroPropio() throws {
        let companion = try makeCompanion()
        let medication = Medication(name: "Contal 150")
        companion.medications.append(medication)
        medication.doses.append(MedicationDose(administeredAt: .test(2026, 9, 10, hour: 9)))
        medication.doses.append(MedicationDose(administeredAt: .test(2026, 9, 10, hour: 21)))

        let snapshot = DashboardBuilder.snapshot(for: companion, on: .test(2026, 9, 10))

        #expect(snapshot.recentActivity.filter { $0.detail == "Toma anotada" }.count == 2)
    }

    /// Una toma pasó: no está "activa" ni "suspendida". El estado es el de la
    /// medicación, y repetirlo en cada toma llenaría la pantalla de chips.
    @Test
    func laTomaNoLlevaChipDeEstado() {
        let dose = MedicationDose(administeredAt: .test(2026, 9, 10))

        #expect(dose.timelineStatus == nil)
    }

    /// La fila del tablero tiene que saber a qué medicación anotarle la toma, o
    /// la casilla no aparece y volvemos al problema del principio.
    @Test
    func laMedicacionEnCursoOfreceAnotarUnaToma() throws {
        let companion = try makeCompanion()
        let medication = Medication(name: "Contal 150", startDate: .test(2024, 10, 9))
        companion.medications.append(medication)

        let snapshot = DashboardBuilder.snapshot(for: companion, on: .test(2026, 9, 10))
        let fila = snapshot.currentStatus.first { $0.title == "Contal 150" }

        #expect(fila?.recordableMedicationID == medication.id)
    }

    /// Un tratamiento no se "toma": la casilla no tiene que aparecerle.
    @Test
    func unTratamientoNoOfreceAnotarUnaToma() throws {
        let companion = try makeCompanion()
        let treatment = Treatment(name: "Fisioterapia", startDate: .test(2026, 9, 1))
        companion.treatments.append(treatment)

        let snapshot = DashboardBuilder.snapshot(for: companion, on: .test(2026, 9, 10))
        let fila = snapshot.currentStatus.first { $0.title == "Fisioterapia" }

        #expect(fila != nil)
        #expect(fila?.recordableMedicationID == nil)
    }

    private func makeCompanion() throws -> Companion {
        let companion = Companion(name: "Lu", species: .dog)
        context.insert(companion)
        return companion
    }
}
