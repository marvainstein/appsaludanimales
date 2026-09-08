import SwiftData
import SwiftUI

/// Veterinario de cabecera y persona responsable.
///
/// Son los dos teléfonos del modo emergencia. Se cargan juntos y en una sola
/// pantalla porque se cargan una vez y casi nunca se vuelven a tocar.
struct CompanionContactsView: View {
    let companion: Companion

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var veterinarianName = ""
    @State private var veterinarianClinic = ""
    @State private var veterinarianPhone = ""
    @State private var responsibleName = ""
    @State private var responsiblePhone = ""
    @State private var hasLoaded = false
    @State private var saveFailed = false

    var body: some View {
        Form {
            Section {
                LabeledTextField(
                    label: String(localized: "Nombre"),
                    text: $veterinarianName,
                    autocapitalization: .words
                )

                LabeledTextField(
                    label: String(localized: "Clínica"),
                    text: $veterinarianClinic,
                    autocapitalization: .words
                )

                LabeledTextField(
                    label: String(localized: "Teléfono"),
                    text: $veterinarianPhone,
                    hint: String(localized: "Se puede tocar para llamar desde el modo emergencia."),
                    keyboardType: .phonePad
                )
            } header: {
                Text("Veterinario de cabecera")
            }

            Section {
                LabeledTextField(
                    label: String(localized: "Nombre"),
                    text: $responsibleName,
                    autocapitalization: .words
                )

                LabeledTextField(
                    label: String(localized: "Teléfono"),
                    text: $responsiblePhone,
                    keyboardType: .phonePad
                )
            } header: {
                Text("Persona responsable")
            } footer: {
                Text("Si dejás un nombre vacío, ese contacto se quita.")
            }

            PrimaryButtonSection(
                title: String(localized: "Guardar contactos"),
                action: save
            )
        }
        .navigationTitle(Text("Contactos"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
        .alert(Text("No pudimos guardar"), isPresented: $saveFailed) {
            Button("Entendido", role: .cancel) { saveFailed = false }
        } message: {
            Text("Los contactos no se guardaron. Podés intentar de nuevo en un momento.")
        }
    }

    // MARK: - Carga y guardado

    private func load() {
        guard !hasLoaded else { return }
        hasLoaded = true

        if let veterinarian = currentVeterinarian {
            veterinarianName = veterinarian.name
            veterinarianClinic = veterinarian.clinic ?? ""
            veterinarianPhone = veterinarian.phone ?? ""
        }

        if let person = currentResponsiblePerson {
            responsibleName = person.name
            responsiblePhone = person.phone ?? ""
        }
    }

    private var currentVeterinarian: Professional? {
        companion.professionals.first(where: \.isPrimaryVeterinarian)
            ?? companion.professionals.first
    }

    private var currentResponsiblePerson: ResponsiblePerson? {
        companion.responsiblePeople.first(where: \.isPrimary)
            ?? companion.responsiblePeople.first
    }

    private func save() {
        saveVeterinarian()
        saveResponsiblePerson()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveFailed = true
        }
    }

    private func saveVeterinarian() {
        let name = trimmed(veterinarianName)
        let existing = currentVeterinarian

        guard !name.isEmpty else {
            if let existing { modelContext.delete(existing) }
            return
        }

        let veterinarian = existing ?? {
            let created = Professional(isPrimaryVeterinarian: true)
            modelContext.insert(created)
            companion.professionals.append(created)
            return created
        }()

        veterinarian.name = name
        veterinarian.clinic = optional(veterinarianClinic)
        veterinarian.phone = optional(veterinarianPhone)
        veterinarian.isPrimaryVeterinarian = true
    }

    private func saveResponsiblePerson() {
        let name = trimmed(responsibleName)
        let existing = currentResponsiblePerson

        guard !name.isEmpty else {
            if let existing { modelContext.delete(existing) }
            return
        }

        let person = existing ?? {
            let created = ResponsiblePerson(isPrimary: true)
            modelContext.insert(created)
            companion.responsiblePeople.append(created)
            return created
        }()

        person.name = name
        person.phone = optional(responsiblePhone)
        person.isPrimary = true
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func optional(_ value: String) -> String? {
        let trimmed = trimmed(value)
        return trimmed.isEmpty ? nil : trimmed
    }
}
