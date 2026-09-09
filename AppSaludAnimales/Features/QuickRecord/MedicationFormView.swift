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

    /// Con una medicación ya guardada, la misma pantalla la edita: cambiar una
    /// dosis mal anotada no debería obligar a borrar y volver a cargar todo,
    /// porque eso también borraría las tomas ya registradas.
    private let editing: Medication?

    @Environment(\.modelContext) private var modelContext

    @State private var name: String
    @State private var dose: String
    @State private var times: [Date]
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var indications: String
    @State private var reminderEnabled: Bool
    @State private var activeAlert: ActiveAlert?

    init(
        companion: Companion,
        editing: Medication? = nil,
        onFinished: @escaping () -> Void = {}
    ) {
        self.companion = companion
        self.editing = editing
        self.onFinished = onFinished
        _name = State(initialValue: editing?.name ?? "")
        _dose = State(initialValue: editing?.dose ?? "")
        _times = State(initialValue: MedicationSchedule.times(for: editing))
        _startDate = State(initialValue: editing?.startDate ?? Date())
        _hasEndDate = State(initialValue: editing?.endDate != nil)
        _endDate = State(initialValue: editing?.endDate ?? Date())
        _indications = State(initialValue: editing?.indications ?? "")
        _reminderEnabled = State(initialValue: editing?.reminderEnabled ?? true)
    }

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
                ForEach(times.indices, id: \.self) { index in
                    DatePicker(
                        selection: $times[index],
                        displayedComponents: .hourAndMinute
                    ) {
                        Text("Horario \(index + 1)")
                    }
                }
                .onDelete { times.remove(atOffsets: $0) }

                Button {
                    times.append(MedicationSchedule.nextSuggestedTime(after: times))
                } label: {
                    Label {
                        Text("Agregar un horario")
                    } icon: {
                        Image(systemName: "plus")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
                .accessibilityIdentifier("medicationForm.addTime")
            } header: {
                Text("Cuándo se administra")
            } footer: {
                Text(times.isEmpty
                    ? "Si todavía no sabés los horarios, podés dejarlo vacío y agregarlos después."
                    : "La app avisa a esa hora, todos los días, mientras dure la medicación. Para borrar un horario, deslizalo hacia la izquierda.")
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
                Text("Avisa a los horarios que cargaste arriba. Si no cargaste ninguno, no hay nada que avisar.")
            }

            PrimaryButtonSection(
                title: editing == nil
                    ? String(localized: "Guardar la medicación")
                    : String(localized: "Guardar los cambios"),
                hint: canSave ? nil : String(localized: "Escribí el nombre para poder guardarla"),
                isEnabled: canSave,
                action: { save(force: false) }
            )
        }
        .navigationTitle(Text(editing == nil
            ? String(localized: "Medicación nueva")
            : String(localized: "Editar la medicación")))
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

    /// Antes de guardar, avisa si ya hay una medicación en curso con el mismo
    /// nombre y propone registrar una toma, que suele ser lo que se quería
    /// hacer. Igual que con las dosis: es un aviso, no un candado.
    private func save(force: Bool) {
        if !force, let existing = duplicateMedication() {
            activeAlert = .duplicate(message: MedicationDuplicationCheck.warningMessage(for: existing.name))
            return
        }

        let medication = editing ?? Medication(startDate: startDate)

        medication.name = trimmedName
        medication.dose = optional(dose)
        medication.startDate = startDate
        medication.endDate = hasEndDate ? endDate : nil
        medication.exactTimes = times.sorted()
        // Los momentos del día quedan vacíos: la medicación pasa a tener
        // horarios de verdad y no una franja.
        medication.timesOfDay = []
        medication.indications = optional(indications)
        medication.reminderEnabled = reminderEnabled

        if editing == nil {
            companion.medications.append(medication)
        }

        do {
            try modelContext.save()
            ReminderSync.refresh(using: modelContext)
            onFinished()
        } catch {
            activeAlert = .saveFailed
        }
    }

    /// Al editar, la propia medicación no cuenta como duplicado de sí misma.
    private func duplicateMedication() -> Medication? {
        companion.activeMedications().first {
            $0.id != editing?.id
                && MedicationDuplicationCheck.isSameMedication($0.name, trimmedName)
        }
    }

    private func optional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
