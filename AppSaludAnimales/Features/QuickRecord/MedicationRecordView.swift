import SwiftData
import SwiftUI

/// Medicación: registrar una toma de algo que ya está en curso, o agregar una
/// medicación nueva.
///
/// El caso frecuente es el primero — "¿ya le di la pastilla?" — así que las
/// medicaciones activas aparecen arriba, listas para tocar.
struct MedicationRecordView: View {
    let companion: Companion
    var onFinished: () -> Void = {}

    @Environment(\.modelContext) private var modelContext

    @State private var activeAlert: ActiveAlert?

    /// Un único aviso por vez: dos alertas sobre la misma vista compiten entre
    /// sí y solo una llega a mostrarse.
    private enum ActiveAlert {
        /// Una toma que espera confirmación porque ya hay otra registrada cerca.
        case duplicate(medication: Medication, date: Date, message: String)
        case saveFailed

        var title: String {
            switch self {
            case .duplicate: String(localized: "¿Registramos la toma igual?")
            case .saveFailed: String(localized: "No pudimos guardar")
            }
        }

        var message: String {
            switch self {
            case let .duplicate(_, _, message): message
            case .saveFailed: String(localized: "La toma no se guardó. Podés intentar de nuevo en un momento.")
            }
        }
    }

    private var activeMedications: [Medication] {
        companion.activeMedications()
    }

    var body: some View {
        Form {
            if activeMedications.isEmpty {
                Section {
                    Text("Todavía no hay medicaciones en curso. Podés agregar una acá abajo.")
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)
                }
            } else {
                Section {
                    ForEach(activeMedications) { medication in
                        doseRow(for: medication)
                    }
                } header: {
                    Text("Registrar una toma")
                } footer: {
                    Text("Se guarda con la hora de este momento.")
                }
            }

            Section {
                NavigationLink {
                    MedicationFormView(companion: companion, onFinished: onFinished)
                } label: {
                    Label {
                        Text("Agregar una medicación nueva")
                    } icon: {
                        Image(systemName: "plus")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
            }
        }
        .navigationTitle(Text("Medicación"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            Text(activeAlert?.title ?? ""),
            isPresented: Binding(
                get: { activeAlert != nil },
                set: { if !$0 { activeAlert = nil } }
            )
        ) {
            if case let .duplicate(medication, date, _) = activeAlert {
                Button("Registrar igual") {
                    activeAlert = nil
                    record(medication: medication, at: date, force: true)
                }
                Button("Mejor no", role: .cancel) { activeAlert = nil }
            } else {
                Button("Entendido", role: .cancel) { activeAlert = nil }
            }
        } message: {
            Text(activeAlert?.message ?? "")
        }
    }

    private func doseRow(for medication: Medication) -> some View {
        Button {
            record(medication: medication, at: Date(), force: false)
        } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(medication.name)
                        .font(AppFont.cardTitle)
                        .foregroundStyle(Palette.ink)

                    if let detail = doseDetail(for: medication) {
                        Text(detail)
                            .font(AppFont.secondary)
                            .foregroundStyle(Palette.inkMuted)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "checkmark.circle")
                    .font(.title3)
                    .foregroundStyle(Palette.accent)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Spacing.minimumTapTarget)
        }
        .accessibilityLabel(Text(medication.name))
        .accessibilityHint(Text("Registra una toma ahora"))
    }

    private func doseDetail(for medication: Medication) -> String? {
        var parts: [String] = []

        if let dose = medication.dose, !dose.isEmpty {
            parts.append(dose)
        }

        if let lastDose = medication.doses.map(\.administeredAt).max() {
            parts.append(String(localized: "última toma \(DateDescription.relative(lastDose).lowercased())"))
        }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Antes de guardar, avisa si ya hay una toma cercana registrada. Es un
    /// aviso, no un candado: la persona decide.
    private func record(medication: Medication, at date: Date, force: Bool) {
        if !force, let conflict = medication.conflictingDose(for: date) {
            activeAlert = .duplicate(
                medication: medication,
                date: date,
                message: DoseDuplicationCheck.warningMessage(for: conflict)
            )
            return
        }

        medication.doses.append(MedicationDose(administeredAt: date))

        do {
            try modelContext.save()
            onFinished()
        } catch {
            activeAlert = .saveFailed
        }
    }
}
