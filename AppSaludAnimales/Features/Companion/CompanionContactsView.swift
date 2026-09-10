import SwiftData
import SwiftUI

/// Las personas a cargo de un compañero.
///
/// Las veterinarias tienen su propia pantalla, donde se pueden guardar varias.
/// Acá vivían las dos cosas juntas y era un problema real: esta pantalla
/// cargaba una sola veterinaria y borraba la que quedaba sin nombre, así que
/// abrirla después de guardar tres podía hacer desaparecer datos que la persona
/// había cargado en otro lado. Cada cosa se edita en un solo lugar.
struct CompanionContactsView: View {
    let companion: Companion

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var responsibleName = ""
    @State private var responsiblePhone = ""
    @State private var secondResponsibleName = ""
    @State private var secondResponsiblePhone = ""
    @State private var hasLoaded = false
    @State private var saveFailed = false

    var body: some View {
        Form {
            Section {
                LabeledTextField(
                    label: String(localized: "Nombre"),
                    text: $responsibleName,
                    autocapitalization: .words
                )

                LabeledTextField(
                    label: String(localized: "Teléfono"),
                    text: $responsiblePhone,
                    hint: String(localized: "Se puede tocar para llamar desde el modo emergencia."),
                    keyboardType: .phonePad
                )
            } header: {
                Text("Persona a cargo")
            }

            Section {
                LabeledTextField(
                    label: String(localized: "Nombre"),
                    text: $secondResponsibleName,
                    autocapitalization: .words
                )

                LabeledTextField(
                    label: String(localized: "Teléfono"),
                    text: $secondResponsiblePhone,
                    keyboardType: .phonePad
                )
            } header: {
                Text("Otra persona a cargo")
            } footer: {
                Text("Para cuando el cuidado se comparte entre dos personas. Las dos aparecen en el modo emergencia. Si dejás un nombre vacío, ese contacto se quita.")
            }

            PrimaryButtonSection(
                title: String(localized: "Guardar contactos"),
                action: save
            )
        }
        .navigationTitle(Text("Personas a cargo"))
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

        let people = companion.orderedResponsiblePeople

        if let person = people.first {
            responsibleName = person.name
            responsiblePhone = person.phone ?? ""
        }

        if people.count > 1 {
            secondResponsibleName = people[1].name
            secondResponsiblePhone = people[1].phone ?? ""
        }
    }

    private func save() {
        let existing = companion.orderedResponsiblePeople

        savePerson(
            name: responsibleName,
            phone: responsiblePhone,
            existing: existing.first,
            isPrimary: true
        )

        savePerson(
            name: secondResponsibleName,
            phone: secondResponsiblePhone,
            existing: existing.count > 1 ? existing[1] : nil,
            isPrimary: false
        )

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveFailed = true
        }
    }

    private func savePerson(
        name: String,
        phone: String,
        existing: ResponsiblePerson?,
        isPrimary: Bool
    ) {
        let trimmedName = trimmed(name)

        guard !trimmedName.isEmpty else {
            if let existing { modelContext.delete(existing) }
            return
        }

        let person = existing ?? {
            let created = ResponsiblePerson(isPrimary: isPrimary)
            modelContext.insert(created)
            companion.responsiblePeople.append(created)
            return created
        }()

        person.name = trimmedName
        person.phone = optional(phone)
        person.isPrimary = isPrimary
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func optional(_ value: String) -> String? {
        let trimmed = trimmed(value)
        return trimmed.isEmpty ? nil : trimmed
    }
}
