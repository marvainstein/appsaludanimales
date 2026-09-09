import SwiftData
import SwiftUI

/// Anotar un tratamiento o una prevención.
///
/// Un tratamiento es lo que dura: kinesiología, una dieta indicada, la
/// desparasitación de todos los meses. Se separa de la medicación porque no se
/// toma en horarios, se sostiene en el tiempo, y porque mezclarlos convertiría
/// la lista de medicaciones en una lista de todo.
struct TreatmentRecordView: View {
    let companion: Companion
    var onFinished: () -> Void = {}

    private let editing: Treatment?

    @Environment(\.modelContext) private var modelContext

    @State private var name: String
    @State private var category: String
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var frequency: String
    @State private var place: String
    @State private var notes: String
    @State private var isPreventive: Bool
    @State private var saveErrorMessage: String?

    init(
        companion: Companion,
        editing: Treatment? = nil,
        onFinished: @escaping () -> Void = {}
    ) {
        self.companion = companion
        self.editing = editing
        self.onFinished = onFinished
        _name = State(initialValue: editing?.name ?? "")
        _category = State(initialValue: editing?.category ?? "")
        _startDate = State(initialValue: editing?.startDate ?? Date())
        _hasEndDate = State(initialValue: editing?.endDate != nil)
        _endDate = State(initialValue: editing?.endDate ?? Date())
        _frequency = State(initialValue: editing?.frequency ?? "")
        _place = State(initialValue: editing?.place ?? "")
        _notes = State(initialValue: editing?.notes ?? "")
        _isPreventive = State(initialValue: editing?.isPreventive ?? false)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section {
                LabeledTextField(
                    label: String(localized: "Qué tratamiento"),
                    text: $name,
                    hint: String(localized: "Por ejemplo: kinesiología, dieta renal, antipulgas."),
                    isRequired: true,
                    autocapitalization: .sentences
                )

                LabeledTextField(
                    label: String(localized: "Categoría"),
                    text: $category,
                    autocapitalization: .sentences
                )

                Toggle(isOn: $isPreventive) {
                    Text("Es una prevención")
                }
            } header: {
                Text("Tratamiento")
            } footer: {
                Text("Marcá prevención para lo que se hace estando sano: antipulgas, desparasitación, control de rutina.")
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
                    label: String(localized: "Cada cuánto"),
                    text: $frequency,
                    hint: String(localized: "Con tus palabras: dos veces por semana, todos los meses.")
                )

                LabeledTextField(
                    label: String(localized: "Dónde"),
                    text: $place,
                    autocapitalization: .words
                )
            } header: {
                Text("Duración")
            }

            Section {
                LabeledTextField(
                    label: String(localized: "Notas"),
                    text: $notes,
                    hint: String(localized: "Lo que dijo el veterinario, con sus palabras.")
                )
            } header: {
                Text("Detalles")
            }

            PrimaryButtonSection(
                title: editing == nil
                    ? String(localized: "Guardar el tratamiento")
                    : String(localized: "Guardar los cambios"),
                hint: canSave ? nil : String(localized: "Escribí qué tratamiento es para poder guardarlo"),
                isEnabled: canSave,
                action: save
            )
        }
        .navigationTitle(Text(editing == nil
            ? String(localized: "Tratamiento")
            : String(localized: "Editar el tratamiento")))
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

    private func save() {
        let treatment = editing ?? Treatment(startDate: startDate)

        treatment.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        treatment.category = optional(category)
        treatment.startDate = startDate
        treatment.endDate = hasEndDate ? endDate : nil
        treatment.frequency = optional(frequency)
        treatment.place = optional(place)
        treatment.notes = optional(notes)
        treatment.isPreventive = isPreventive

        if editing == nil {
            companion.treatments.append(treatment)
        }

        do {
            try modelContext.save()
            onFinished()
        } catch {
            saveErrorMessage = String(localized: "El tratamiento no se guardó. Podés intentar de nuevo en un momento.")
        }
    }

    private func optional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
