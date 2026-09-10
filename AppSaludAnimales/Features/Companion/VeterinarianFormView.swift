import SwiftData
import SwiftUI

/// Cargar o cambiar una veterinaria.
struct VeterinarianFormView: View {
    let companion: Companion

    private let editing: Professional?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var clinic: String
    @State private var phone: String
    @State private var notes: String
    @State private var isPrimary: Bool
    @State private var saveFailed = false

    init(companion: Companion, editing: Professional? = nil) {
        self.companion = companion
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "")
        _clinic = State(initialValue: editing?.clinic ?? "")
        _phone = State(initialValue: editing?.phone ?? "")
        _notes = State(initialValue: editing?.notes ?? "")
        _isPrimary = State(initialValue: editing?.isPrimaryVeterinarian ?? companion.professionals.isEmpty)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledTextField(
                        label: String(localized: "Nombre"),
                        text: $name,
                        hint: String(localized: "El de la veterinaria o el de la persona, como la tengas en la cabeza."),
                        isRequired: true,
                        autocapitalization: .words
                    )

                    LabeledTextField(
                        label: String(localized: "Clínica"),
                        text: $clinic,
                        autocapitalization: .words
                    )

                    LabeledTextField(
                        label: String(localized: "Teléfono"),
                        text: $phone,
                        keyboardType: .phonePad
                    )
                } header: {
                    Text("Datos")
                        .foregroundStyle(Palette.inkMuted)
                } footer: {
                    Text("Sin teléfono no se puede llamar desde el modo emergencia, que es para lo que sirve tenerla cargada.")
                        .foregroundStyle(Palette.inkMuted)
                }

                Section {
                    LabeledTextField(
                        label: String(localized: "Notas"),
                        text: $notes,
                        hint: String(localized: "Lo que quieras acordarte: atiende de urgencia, solo con turno, acá la operaron.")
                    )

                    Toggle(isOn: $isPrimary) {
                        Text("Es la de cabecera")
                    }
                } footer: {
                    Text("La de cabecera aparece primera en el modo emergencia.")
                        .foregroundStyle(Palette.inkMuted)
                }

                PrimaryButtonSection(
                    title: String(localized: "Guardar"),
                    hint: canSave ? nil : String(localized: "Escribí un nombre para poder guardarla"),
                    isEnabled: canSave,
                    identifier: "veterinarian.save",
                    action: save
                )
            }
            .navigationTitle(Text(editing == nil
                ? String(localized: "Nueva veterinaria")
                : String(localized: "Editar la veterinaria")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancelar")
                    }
                }
            }
            .alert(Text("No pudimos guardar"), isPresented: $saveFailed) {
                Button("Entendido", role: .cancel) { saveFailed = false }
            } message: {
                Text("Podés intentar de nuevo en un momento.")
            }
        }
    }

    private func save() {
        let professional = editing ?? Professional()

        professional.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        professional.clinic = optional(clinic)
        professional.phone = optional(phone)
        professional.notes = optional(notes)
        professional.isPrimaryVeterinarian = isPrimary

        if editing == nil {
            modelContext.insert(professional)
            companion.professionals.append(professional)
        }

        // De cabecera hay una sola: marcar una nueva desmarca la anterior, en
        // vez de dejar dos primeras y que el orden lo decida el azar.
        if isPrimary {
            for other in companion.professionals where other !== professional {
                other.isPrimaryVeterinarian = false
            }
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveFailed = true
        }
    }

    private func optional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
