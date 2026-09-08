import SwiftData
import SwiftUI

/// Alta de una medicación.
///
/// Los horarios pueden ser exactos o momentos del día: obligar a elegir una hora
/// puntual cuando la indicación fue "a la mañana y a la noche" agrega precisión
/// falsa y fricción real.
struct MedicationFormView: View {
    let companion: Companion
    var onFinished: () -> Void = {}

    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var dose = ""
    @State private var timesOfDay: Set<TimeOfDay> = []
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var indications = ""
    @State private var reminderEnabled = true
    @State private var activeAlert: ActiveAlert?

    /// Un único aviso por vez: dos alertas sobre la misma vista compiten entre
    /// sí y solo una llega a mostrarse.
    private enum ActiveAlert {
        case duplicate(message: String)
        case saveFailed

        var title: String {
            switch self {
            case .duplicate: String(localized: "¿La agregamos igual?")
            case .saveFailed: String(localized: "No pudimos guardar")
            }
        }

        var message: String {
            switch self {
            case let .duplicate(message): message
            case .saveFailed: String(localized: "La medicación no se guardó. Podés intentar de nuevo en un momento.")
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                LabeledTextField(
                    label: String(localized: "Nombre"),
                    text: $name,
                    isRequired: true,
                    autocapitalization: .words
                )

                LabeledTextField(
                    label: String(localized: "Dosis"),
                    text: $dose,
                    hint: String(localized: "Por ejemplo: media pastilla, 10 mg, 2 ml.")
                )
            } header: {
                Text("Medicación")
            }

            Section {
                ForEach(TimeOfDay.allCases, id: \.self) { moment in
                    Button {
                        toggle(moment)
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: timesOfDay.contains(moment)
                                ? "checkmark.circle.fill"
                                : "circle")
                                .foregroundStyle(Palette.accent)
                                .accessibilityHidden(true)

                            Text(moment.label)
                                .foregroundStyle(Palette.ink)

                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: Spacing.minimumTapTarget)
                    }
                    .accessibilityLabel(Text(moment.label))
                    .accessibilityValue(Text(timesOfDay.contains(moment)
                        ? String(localized: "Elegido")
                        : String(localized: "No elegido")))
                    .accessibilityAddTraits(timesOfDay.contains(moment) ? [.isSelected] : [])
                }
            } header: {
                Text("Cuándo se administra")
            } footer: {
                Text("Podés elegir más de uno, o ninguno si todavía no lo sabés.")
            }

            Section {
                DatePicker(selection: $startDate, displayedComponents: .date) {
                    Text("Empieza")
                }

                Toggle(isOn: $hasEndDate) {
                    Text("Tiene fecha de finalización")
                }

                if hasEndDate {
                    DatePicker(selection: $endDate, in: startDate..., displayedComponents: .date) {
                        Text("Termina")
                    }
                }

                LabeledTextField(
                    label: String(localized: "Indicaciones"),
                    text: $indications,
                    hint: String(localized: "Lo que dijo el veterinario, con sus palabras.")
                )
            } header: {
                Text("Duración")
            }

            Section {
                Toggle(isOn: $reminderEnabled) {
                    Text("Avisarme cuando toca")
                }
            } footer: {
                Text("Usa los momentos del día que elegiste. Podés cambiarlo después desde Recordatorios.")
            }

            PrimaryButtonSection(
                title: String(localized: "Guardar la medicación"),
                hint: canSave ? nil : String(localized: "Escribí el nombre para poder guardarla"),
                isEnabled: canSave,
                action: { save(force: false) }
            )
        }
        .navigationTitle(Text("Medicación nueva"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            Text(activeAlert?.title ?? ""),
            isPresented: Binding(
                get: { activeAlert != nil },
                set: { if !$0 { activeAlert = nil } }
            )
        ) {
            if case .duplicate = activeAlert {
                Button("Agregar igual") {
                    activeAlert = nil
                    save(force: true)
                }
                Button("Mejor no", role: .cancel) { activeAlert = nil }
            } else {
                Button("Entendido", role: .cancel) { activeAlert = nil }
            }
        } message: {
            Text(activeAlert?.message ?? "")
        }
    }

    private func toggle(_ moment: TimeOfDay) {
        if timesOfDay.contains(moment) {
            timesOfDay.remove(moment)
        } else {
            timesOfDay.insert(moment)
        }
    }

    /// Antes de guardar, avisa si ya hay una medicación en curso con el mismo
    /// nombre y propone registrar una toma, que suele ser lo que se quería
    /// hacer. Igual que con las dosis: es un aviso, no un candado.
    private func save(force: Bool) {
        if !force, let existing = duplicateMedication() {
            activeAlert = .duplicate(message: MedicationDuplicationCheck.warningMessage(for: existing.name))
            return
        }

        let medication = Medication(
            name: trimmedName,
            dose: optional(dose),
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil
        )
        medication.timesOfDay = TimeOfDay.allCases.filter(timesOfDay.contains)
        medication.indications = optional(indications)
        medication.reminderEnabled = reminderEnabled
        companion.medications.append(medication)

        do {
            try modelContext.save()
            onFinished()
        } catch {
            activeAlert = .saveFailed
        }
    }

    private func duplicateMedication() -> Medication? {
        companion.activeMedications().first {
            MedicationDuplicationCheck.isSameMedication($0.name, trimmedName)
        }
    }

    private func optional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
