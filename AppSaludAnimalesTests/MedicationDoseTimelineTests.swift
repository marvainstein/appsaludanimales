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

        #expect(fila?.record == .medication(medication.id))
    }

    /// Un tratamiento también se anota, pero es una sesión y no una toma: la
    /// casilla tiene que decirlo con la palabra correcta.
    @Test
    func elTratamientoAnotaSesionesYNoTomas() throws {
        let companion = try makeCompanion()
        let treatment = Treatment(name: "Fisioterapia", startDate: .test(2026, 9, 1))
        companion.treatments.append(treatment)

        let snapshot = DashboardBuilder.snapshot(for: companion, on: .test(2026, 9, 10))
        let fila = snapshot.currentStatus.first { $0.title == "Fisioterapia" }
        let record = try #require(fila?.record)

        #expect(record == .treatment(treatment.id))
        #expect(DashboardView.recordLabel(for: record) == "Anotar sesión")
    }

    /// Luli empezó yendo dos veces por semana y después cada quince días. El
    /// campo de frecuencia dice cómo es ahora; las sesiones dicen cómo fue.
    @Test
    func lasSesionesDeUnTratamientoSonRegistrosPropios() throws {
        let companion = try makeCompanion()
        let treatment = Treatment(name: "Fisioterapia", startDate: .test(2026, 1, 1))
        companion.treatments.append(treatment)
        treatment.sessions.append(TreatmentSession(attendedAt: .test(2026, 9, 3)))
        treatment.sessions.append(TreatmentSession(attendedAt: .test(2026, 9, 10)))

        let snapshot = DashboardBuilder.snapshot(for: companion, on: .test(2026, 9, 10))

        #expect(snapshot.recentActivity.contains { $0.detail == "Sesión anotada" })
        #expect(treatment.sessions.count == 2)
    }

    /// Cinco renglones de actividad reciente llenaban la pantalla apenas
    /// empezaban a entrar las tomas. Dos alcanzan para contestar "¿quedó
    /// anotado lo último que hice?", que es para lo que sirve esa sección.
    @Test
    func laActividadRecienteMuestraDos() throws {
        let companion = try makeCompanion()
        let medication = Medication(name: "Contal 150", startDate: .test(2024, 10, 9))
        companion.medications.append(medication)

        for hour in [8, 12, 16, 20] {
            medication.doses.append(MedicationDose(administeredAt: .test(2026, 9, 10, hour: hour)))
        }

        let snapshot = DashboardBuilder.snapshot(for: companion, on: .test(2026, 9, 10))

        #expect(snapshot.recentActivity.count == 2)
    }

    /// El caso de Luli: primero un cuarto de pastilla, después media, después
    /// dos. Si la toma leyera la dosis actual de la medicación, editarla
    /// reescribiría toda la historia y parecería que siempre tomó dos.
    @Test
    func cadaTomaConservaLaDosisConLaQueSeDio() throws {
        let companion = try makeCompanion()
        let medication = Medication(name: "Contal 150", dose: "Un cuarto de pastilla")
        companion.medications.append(medication)

        medication.doses.append(
            MedicationDose(administeredAt: .test(2026, 3, 1), dose: medication.dose)
        )

        medication.dose = "Media pastilla"
        medication.doses.append(
            MedicationDose(administeredAt: .test(2026, 6, 1), dose: medication.dose)
        )

        medication.dose = "Dos pastillas"

        let dosis = medication.doses
            .sorted { $0.administeredAt < $1.administeredAt }
            .map(\.dose)

        #expect(dosis == ["Un cuarto de pastilla", "Media pastilla"])
        #expect(medication.dose == "Dos pastillas")
    }

    /// Un tratamiento también se abre desde "En curso": si una fila muestra
    /// información, tocarla tiene que llevar a la información completa.
    @Test
    func unTratamientoEnCursoTambienSePuedeAbrir() throws {
        let companion = try makeCompanion()
        let treatment = Treatment(name: "Fisioterapia", startDate: .test(2026, 9, 1))
        companion.treatments.append(treatment)

        let snapshot = DashboardBuilder.snapshot(for: companion, on: .test(2026, 9, 10))
        let fila = snapshot.currentStatus.first { $0.title == "Fisioterapia" }

        #expect(fila?.record == .treatment(treatment.id))
    }

    /// El historial completo es la extensión de la actividad reciente, no una
    /// lista aparte: si anotás una toma a las 20:57, tiene que aparecer arriba
    /// de todo. Antes no aparecía en ningún lado y la medicación figuraba en la
    /// fecha en que empezó, así que un Contal que arrancó en 2024 quedaba al
    /// fondo aunque se hubiera dado hoy.
    @Test
    func loQueSeAnotoHoyEncabezaElHistorial() throws {
        let companion = try makeCompanion()

        let medication = Medication(name: "Contal 150", startDate: .test(2024, 10, 9))
        companion.medications.append(medication)

        let treatment = Treatment(name: "Fisioterapia", startDate: .test(2026, 1, 1))
        companion.treatments.append(treatment)
        treatment.sessions.append(TreatmentSession(attendedAt: .test(2026, 9, 10, hour: 11)))

        medication.doses.append(MedicationDose(administeredAt: .test(2026, 9, 11, hour: 20, minute: 57)))

        let entradas = HistoryBuilder.entries(for: companion)

        #expect(entradas.first?.title == "Contal 150")
        #expect(entradas.first?.detail?.contains("toma") == true)
    }

    /// Dos tomas del mismo día son un renglón en el historial, no dos: dos
    /// tomas diarias durante un año son setecientos treinta renglones
    /// repitiendo el mismo nombre. Cada una con su hora está en "Ver todas".
    @Test
    func lasTomasDelMismoDiaSeAgrupanEnElHistorial() throws {
        let companion = try makeCompanion()
        let medication = Medication(name: "Contal 150", dose: "Media pastilla", startDate: .test(2024, 10, 9))
        companion.medications.append(medication)

        for hour in [9, 21] {
            medication.doses.append(
                MedicationDose(administeredAt: .test(2026, 9, 11, hour: hour), dose: medication.dose)
            )
        }

        let tomas = HistoryBuilder.entries(for: companion)
            .filter { $0.detail?.contains("tomas") == true }

        #expect(tomas.count == 1)
        #expect(tomas.first?.detail == "2 tomas · Media pastilla")
    }

    // MARK: - Un resumen puede resumir, no puede afirmar algo que no pasó

    /// Si en el día hubo dosis distintas, el renglón agrupado las dice todas.
    /// Antes mostraba una cualquiera del montón: alguien que dio cinco
    /// pastillas, después dos y después una, leía que había dado tres veces una.
    @Test
    func elRenglonAgrupadoDiceTodasLasDosisDelDia() throws {
        let companion = try makeCompanion()
        let medication = Medication(name: "Contal 150", startDate: .test(2024, 10, 9))
        companion.medications.append(medication)

        for (hour, dose) in [(9, "5 pastillas"), (14, "2 pastillas"), (21, "1 pastilla")] {
            medication.doses.append(
                MedicationDose(administeredAt: .test(2026, 9, 11, hour: hour), dose: dose)
            )
        }

        let entrada = try #require(
            HistoryBuilder.entries(for: companion).first { $0.detail?.contains("tomas") == true }
        )

        #expect(entrada.detail == "3 tomas · 5 pastillas, 2 pastillas, 1 pastilla")
    }

    /// Los tramos se filtran por su detalle y no por el título: `entries`
    /// devuelve además el registro de la medicación en sí, fechado el día en que
    /// empezó. En el resumen eso se lee bien —primero cuándo empezó, después los
    /// cambios— pero al contar hay que distinguirlos.
    ///
    /// El resumen que se exporta marca los cambios, no cada toma. Exportar toda
    /// la historia pastilla por pastilla son miles de renglones que repiten lo
    /// mismo; si entre dos renglones no hay nada, siguió igual.
    @Test
    func elResumenExportadoMarcaLosCambiosDeDosis() throws {
        let companion = try makeCompanion()
        let medication = Medication(name: "Contal 150", startDate: .test(2024, 10, 9))
        companion.medications.append(medication)

        // Cuatro meses de una pastilla, y después media.
        for day in 1...4 {
            medication.doses.append(
                MedicationDose(administeredAt: .test(2026, 5, day), dose: "1 pastilla")
            )
        }
        for day in 5...6 {
            medication.doses.append(
                MedicationDose(administeredAt: .test(2026, 5, day), dose: "Media pastilla")
            )
        }

        let cambios = HistoryBuilder.entries(for: companion, rhythm: .byChange)
            .filter { $0.detail?.contains("tomas anotadas") == true }
            .sorted { $0.date < $1.date }

        #expect(cambios.count == 2)
        #expect(cambios.first?.detail == "1 pastilla · 4 tomas anotadas")
        #expect(cambios.last?.detail == "Media pastilla · 2 tomas anotadas")
    }

    /// El renglón del cambio cae el día en que la dosis empezó a usarse, no el
    /// día en que se exportó: así queda en el lugar correcto de la historia.
    @Test
    func elCambioSeFechaCuandoEmpezoAUsarse() throws {
        let companion = try makeCompanion()
        let medication = Medication(name: "Contal 150", startDate: .test(2024, 10, 9))
        companion.medications.append(medication)

        medication.doses.append(MedicationDose(administeredAt: .test(2025, 3, 1), dose: "1 pastilla"))
        medication.doses.append(MedicationDose(administeredAt: .test(2026, 7, 14), dose: "5 pastillas"))

        let cambios = HistoryBuilder.entries(for: companion, rhythm: .byChange)
            .filter { $0.detail?.contains("anotada") == true }
            .sorted { $0.date < $1.date }

        #expect(cambios.first?.date == .test(2025, 3, 1))
        #expect(cambios.last?.date == .test(2026, 7, 14))
    }

    /// Las sesiones se cuentan por mes. Es contar, no interpretar: la app no
    /// dice "pasó de dos veces por semana a cada quince días".
    @Test
    func lasSesionesSeCuentanPorMesEnElResumen() throws {
        let companion = try makeCompanion()
        let treatment = Treatment(name: "Fisioterapia", startDate: .test(2026, 1, 1))
        companion.treatments.append(treatment)

        for day in [3, 10, 17, 24] {
            treatment.sessions.append(TreatmentSession(attendedAt: .test(2026, 3, day)))
        }
        for day in [5, 20] {
            treatment.sessions.append(TreatmentSession(attendedAt: .test(2026, 4, day)))
        }

        let meses = HistoryBuilder.entries(for: companion, rhythm: .byChange)
            .filter { $0.detail?.contains("en el mes") == true }
            .sorted { $0.date < $1.date }

        #expect(meses.count == 2)
        #expect(meses.first?.detail == "4 sesiones en el mes")
        #expect(meses.last?.detail == "2 sesiones en el mes")
    }

    /// La dosis actual pegada a la fecha de inicio se leía como que venía
    /// tomando eso desde entonces. Una dosis cambia.
    @Test
    func elResumenNoDiceQueLaDosisDeAhoraVieneDesdeElComienzo() throws {
        let companion = try makeCompanion()
        let medication = Medication(
            name: "Contal 150",
            dose: "1 pastilla",
            startDate: .test(2024, 10, 9)
        )
        companion.medications.append(medication)

        let report = HealthReportBuilder.report(
            for: companion,
            period: .all,
            sections: [.currentCare],
            on: .test(2026, 9, 11)
        )

        let linea = try #require(
            report.sections.first?.lines.first { $0.text == "Contal 150" }
        )
        let detalle = try #require(linea.detail)

        #expect(detalle.contains("ahora 1 pastilla"))
        #expect(detalle.contains("empezó el"))
        #expect(!detalle.contains("1 pastilla · desde"))
    }

    private func makeCompanion() throws -> Companion {
        let companion = Companion(name: "Lu", species: .dog)
        context.insert(companion)
        return companion
    }
}
