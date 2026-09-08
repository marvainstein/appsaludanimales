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

extension Medication: HealthTimelineItem {
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

    /// Quién registró la dosis. Con varias personas responsables, saber quién
    /// anotó qué es más útil que impedir un registro doble.
    var recordedByName: String?
    var createdAt: Date = Date()

    var medication: Medication?

    init(administeredAt: Date = Date(), recordedByName: String? = nil, notes: String? = nil) {
        self.administeredAt = administeredAt
        self.recordedByName = recordedByName
        self.notes = notes
    }
}
