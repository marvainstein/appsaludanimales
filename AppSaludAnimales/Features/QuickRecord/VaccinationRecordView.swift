import SwiftData
import SwiftUI

/// Registrar una vacuna y, si se conoce, cuándo toca la próxima.
struct VaccinationRecordView: View {
    let companion: Companion
    var onFinished: () -> Void = {}

    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var date = Date()
    @State private var hasNextDueDate = false
    @State private var nextDueDate = Date()
    @State private var notes = ""
    @State private var saveErrorMessage: String?

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
                title: String(localized: "Guardar la vacuna"),
                hint: canSave ? nil : String(localized: "Escribí qué vacuna para poder guardarla"),
                isEnabled: canSave,
                action: save
            )
        }
        .navigationTitle(Text("Vacuna"))
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
        let vaccination = Vaccination(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            nextDueDate: hasNextDueDate ? nextDueDate : nil
        )
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        vaccination.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        companion.vaccinations.append(vaccination)

        do {
            try modelContext.save()
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

    @Environment(\.modelContext) private var modelContext

    @State private var text = ""
    @State private var date = Date()
    @State private var saveErrorMessage: String?

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
                title: String(localized: "Guardar la nota"),
                hint: canSave ? nil : String(localized: "Escribí la nota para poder guardarla"),
                isEnabled: canSave,
                action: save
            )
        }
        .navigationTitle(Text("Nota"))
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
        let note = CompanionNote(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date
        )
        companion.notes.append(note)

        do {
            try modelContext.save()
            onFinished()
        } catch {
            saveErrorMessage = String(localized: "La nota no se guardó. Podés intentar de nuevo en un momento.")
        }
    }
}
