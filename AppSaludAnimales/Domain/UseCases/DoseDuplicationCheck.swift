import Foundation

/// Dosis ya registrada, con quién la registró, para poder avisar antes de anotar
/// una segunda por error entre varias personas responsables.
struct RecordedDose: Equatable, Sendable {
    var administeredAt: Date
    var recordedByName: String?

    init(administeredAt: Date, recordedByName: String? = nil) {
        self.administeredAt = administeredAt
        self.recordedByName = recordedByName
    }
}

/// Aviso visible, no candado: si otra persona ya registró la dosis, se muestra
/// antes de guardar y la persona decide. No bloquea el registro.
enum DoseDuplicationCheck {
    static let defaultWindow: TimeInterval = 60 * 60

    /// Dosis ya registrada más cercana al momento propuesto dentro de la ventana.
    static func conflictingDose(
        for proposedDate: Date,
        among doses: [RecordedDose],
        window: TimeInterval = defaultWindow
    ) -> RecordedDose? {
        doses
            .filter { abs($0.administeredAt.timeIntervalSince(proposedDate)) <= window }
            .min { lhs, rhs in
                abs(lhs.administeredAt.timeIntervalSince(proposedDate))
                    < abs(rhs.administeredAt.timeIntervalSince(proposedDate))
            }
    }

    /// Qué se está por anotar, para que el aviso lo diga con la palabra correcta.
    enum Kind {
        case dose
        case session
    }

    /// Texto del aviso. En pregunta abierta, nunca como reproche ni como error.
    static func warningMessage(
        for dose: RecordedDose,
        kind: Kind = .dose,
        formatter: DateFormatter = .doseTime
    ) -> String {
        let time = formatter.string(from: dose.administeredAt)

        switch kind {
        case .dose:
            if let name = dose.recordedByName, !name.isEmpty {
                return String(localized: "\(name) ya registró esta dosis a las \(time). ¿Querés registrarla igual?")
            }

            return String(localized: "Ya hay una dosis registrada a las \(time). ¿Querés registrarla igual?")

        case .session:
            if let name = dose.recordedByName, !name.isEmpty {
                return String(localized: "\(name) ya registró una sesión a las \(time). ¿Querés registrarla igual?")
            }

            return String(localized: "Ya hay una sesión registrada a las \(time). ¿Querés registrarla igual?")
        }
    }
}

extension DateFormatter {
    static let doseTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
