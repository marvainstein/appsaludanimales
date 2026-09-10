import Foundation
import SwiftData

@Model
final class Medication {
    var id: UUID = UUID()
    var name: String = ""
    var activeIngredient: String?
    var dose: String?
    var doseUnit: String?
    var frequency: String?
    var administrationRoute: String?
    var indications: String?
    var notes: String?
    var startDate: Date = Date()
    var endDate: Date?
    var isSuspended: Bool = false
    /// Igual que vacunas y turnos: una medicación en curso avisa salvo que se
    /// pida lo contrario. Que la app organice es el punto; apagarlo está a un
    /// toque en Recordatorios.
    var reminderEnabled: Bool = true
    var createdAt: Date = Date()

    /// Momentos del día (mañana, noche, según necesidad). Se guardan los valores
    /// crudos de `TimeOfDay`.
    var timeOfDayRawValues: [String] = []

    /// Horarios exactos, cuando la persona los conoce. Convive con los momentos
    /// del día: ninguno de los dos es obligatorio.
    var exactTimes: [Date] = []

    var companion: Companion?
    var prescribedBy: Professional?

    @Relationship(deleteRule: .cascade, inverse: \MedicationDose.medication)
    var doses: [MedicationDose] = []

    init(
        name: String = "",
        activeIngredient: String? = nil,
        dose: String? = nil,
        doseUnit: String? = nil,
        frequency: String? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil
    ) {
        self.name = name
        self.activeIngredient = activeIngredient
        self.dose = dose
        self.doseUnit = doseUnit
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
    }
}

extension Medication {
    /// El estado depende de cuándo se lo mire: una medicación que terminó ayer
    /// estaba activa anteayer. Quien pregunta dice desde qué momento.
    func status(on referenceDate: Date = .now) -> ActivityStatus {
        MedicationStatusResolver.status(
            startDate: startDate,
            endDate: endDate,
            isSuspended: isSuspended,
            on: referenceDate
        )
    }

    var timesOfDay: [TimeOfDay] {
        get { timeOfDayRawValues.compactMap(TimeOfDay.init(rawValue:)) }
        set { timeOfDayRawValues = newValue.map(\.rawValue) }
    }

    /// Dosis ya registradas, para avisar sobre una posible repetición.
    var recordedDoses: [RecordedDose] {
        doses.map {
            RecordedDose(administeredAt: $0.administeredAt, recordedByName: $0.recordedByName)
        }
    }

    /// Dosis en conflicto con el momento propuesto, si la hay.
    func conflictingDose(for proposedDate: Date) -> RecordedDose? {
        DoseDuplicationCheck.conflictingDose(for: proposedDate, among: recordedDoses)
    }
}

/// Cada toma anotada es un registro con su propia fecha.
///
/// Sin esto, la app dejaba anotar una toma y no la mostraba en ningún lado: la
/// medicación aparecía una sola vez, fechada el día en que se cargó, y las tomas
/// posteriores se guardaban sin dejar rastro. La primera persona que probó esto
/// dio la medicación, no vio nada, y concluyó que no había funcionado.
///
/// Aparecen en "Actividad reciente" y en la lista de la propia medicación, no en
/// el historial: dos tomas por día durante un año son setecientos treinta
/// renglones que dirían lo mismo, y el historial existe para encontrar el
/// estudio de cuando estuvo mal de la pata.
extension MedicationDose: HealthTimelineItem {
    var timelineRecordedAt: Date { createdAt }
    var timelineDate: Date { administeredAt }
    var timelineTitle: String { medication?.name ?? String(localized: "Medicación") }
    var timelineCategory: HealthCategory { .medication }

    /// Sin chip de estado: el estado es el de la medicación, no el de la toma.
    /// Una toma no está "activa" ni "suspendida": pasó.
    var timelineStatus: (any StatusPresentable)? { nil }
}

extension Medication: HealthTimelineItem {
    var timelineRecordedAt: Date { createdAt }
    var timelineDate: Date { startDate }
    var timelineTitle: String { name }
    var timelineCategory: HealthCategory { .medication }
    var timelineStatus: (any StatusPresentable)? { status() }
}

@Model
final class MedicationDose {
    var id: UUID = UUID()
    var administeredAt: Date = Date()
    var notes: String?

    /// Con qué dosis se dio, copiada de la medicación en ese momento.
    ///
    /// Es una copia y no una referencia a propósito. Una medicación cambia de
    /// dosis con el tiempo —un cuarto de pastilla, después media, después dos— y
    /// si la toma leyera la dosis actual, toda la historia se reescribiría al
    /// editarla: parecería que siempre tomó dos. Guardándola acá, la lista de
    /// tomas muestra cuándo cambió sin que nadie tenga que anotarlo aparte.
    var dose: String?

    /// Quién registró la dosis. Con varias personas responsables, saber quién
    /// anotó qué es más útil que impedir un registro doble.
    var recordedByName: String?
    var createdAt: Date = Date()

    var medication: Medication?

    init(
        administeredAt: Date = Date(),
        dose: String? = nil,
        recordedByName: String? = nil,
        notes: String? = nil
    ) {
        self.administeredAt = administeredAt
        self.dose = dose
        self.recordedByName = recordedByName
        self.notes = notes
    }
}
