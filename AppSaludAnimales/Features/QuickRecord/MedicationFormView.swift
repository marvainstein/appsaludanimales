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
    @State private var saveErrorMessage: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

            PrimaryButtonSection(
                title: String(localized: "Guardar la medicación"),
                hint: canSave ? nil : String(localized: "Escribí el nombre para poder guardarla"),
                isEnabled: canSave,
                action: save
            )
        }
        .navigationTitle(Text("Medicación nueva"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            Text("No pudimos guardar"),
            isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )
        ) {
            Button("Entendido", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func toggle(_ moment: TimeOfDay) {
        if timesOfDay.contains(moment) {
            timesOfDay.remove(moment)
        } else {
            timesOfDay.insert(moment)
        }
    }

    private func save() {
        let medication = Medication(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            dose: optional(dose),
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil
        )
        medication.timesOfDay = TimeOfDay.allCases.filter(timesOfDay.contains)
        medication.indications = optional(indications)
        companion.medications.append(medication)

        do {
            try modelContext.save()
            onFinished()
        } catch {
            saveErrorMessage = String(localized: "La medicación no se guardó. Podés intentar de nuevo en un momento.")
        }
    }

    private func optional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
