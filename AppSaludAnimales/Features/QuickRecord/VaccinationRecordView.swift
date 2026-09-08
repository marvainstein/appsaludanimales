import SwiftData
import SwiftUI

/// Registrar una vacuna y, si se conoce, cuándo toca la próxima.
struct VaccinationRecordView: View {
    let companion: Companion
    var onFinished: () -> Void = {}

    /// Con una vacuna ya guardada, la misma pantalla la edita.
    private let editing: Vaccination?

    @Environment(\.modelContext) private var modelContext

    @State private var name: String
    @State private var date: Date
    @State private var hasNextDueDate: Bool
    @State private var nextDueDate: Date
    @State private var notes: String
    @State private var saveErrorMessage: String?

    init(
        companion: Companion,
        editing: Vaccination? = nil,
        onFinished: @escaping () -> Void = {}
    ) {
        self.companion = companion
        self.editing = editing
        self.onFinished = onFinished
        _name = State(initialValue: editing?.name ?? "")
        _date = State(initialValue: editing?.date ?? Date())
        _hasNextDueDate = State(initialValue: editing?.nextDueDate != nil)
        _nextDueDate = State(initialValue: editing?.nextDueDate ?? Date())
        _notes = State(initialValue: editing?.notes ?? "")
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section {
                LabeledTextField(
                    label: String(localized: "Qué vacuna"),
                    text: $name,
                    isRequired: true,
                    autocapitalization: .words
                )

                DatePicker(selection: $date, in: ...Date(), displayedComponents: .date) {
                    Text("Fecha de aplicación")
                }
            } header: {
                Text("Vacuna")
            }

            Section {
                Toggle(isOn: $hasNextDueDate) {
                    Text("Sé cuándo toca la próxima")
                }

                if hasNextDueDate {
                    DatePicker(selection: $nextDueDate, displayedComponents: .date) {
                        Text("Próxima aplicación")
                    }
                }

                LabeledTextField(
                    label: String(localized: "Observaciones"),
                    text: $notes
                )
            } header: {
                Text("Próxima")
            } footer: {
                Text("Si cargás la próxima fecha, aparece en Próximamente cuando se acerque.")
            }

            PrimaryButtonSection(
                title: editing == nil
                    ? String(localized: "Guardar la vacuna")
                    : String(localized: "Guardar los cambios"),
                hint: canSave ? nil : String(localized: "Escribí qué vacuna para poder guardarla"),
                isEnabled: canSave,
                action: save
            )
        }
        .navigationTitle(Text(editing == nil
            ? String(localized: "Vacuna")
            : String(localized: "Editar la vacuna")))
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
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let vaccination = editing ?? Vaccination(name: "", date: date)

        vaccination.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        vaccination.date = date
        vaccination.nextDueDate = hasNextDueDate ? nextDueDate : nil
        vaccination.notes = trimmedNotes.isEmpty ? nil : trimmedNotes

        if editing == nil {
            companion.vaccinations.append(vaccination)
        }

        do {
            try modelContext.save()
            ReminderSync.refresh(using: modelContext)
            onFinished()
        } catch {
            saveErrorMessage = String(localized: "La vacuna no se guardó. Podés intentar de nuevo en un momento.")
        }
    }
}

/// Una nota libre: para lo que no entra en ninguna categoría y aun así se quiere
/// recordar.
struct NoteRecordView: View {
    let companion: Companion
    var onFinished: () -> Void = {}

    /// Con una nota ya guardada, la misma pantalla la edita.
    private let editing: CompanionNote?

    @Environment(\.modelContext) private var modelContext

    @State private var text: String
    @State private var date: Date
    @State private var saveErrorMessage: String?

    init(
        companion: Companion,
        editing: CompanionNote? = nil,
        onFinished: @escaping () -> Void = {}
    ) {
        self.companion = companion
        self.editing = editing
        self.onFinished = onFinished
        _text = State(initialValue: editing?.text ?? "")
        _date = State(initialValue: editing?.date ?? Date())
    }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section {
                LabeledTextField(
                    label: String(localized: "Nota"),
                    text: $text,
                    isRequired: true
                )

                DatePicker(selection: $date, displayedComponents: [.date, .hourAndMinute]) {
                    Text("Cuándo")
                }
            } header: {
                Text("Nota")
            }

            PrimaryButtonSection(
                title: editing == nil
                    ? String(localized: "Guardar la nota")
                    : String(localized: "Guardar los cambios"),
                hint: canSave ? nil : String(localized: "Escribí la nota para poder guardarla"),
                isEnabled: canSave,
                action: save
            )
        }
        .navigationTitle(Text(editing == nil
            ? String(localized: "Nota")
            : String(localized: "Editar la nota")))
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
        let note = editing ?? CompanionNote(text: "", date: date)
        note.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        note.date = date

        if editing == nil {
            companion.notes.append(note)
        }

        do {
            try modelContext.save()
            onFinished()
        } catch {
            saveErrorMessage = String(localized: "La nota no se guardó. Podés intentar de nuevo en un momento.")
        }
    }
}
