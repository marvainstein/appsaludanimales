import SwiftData
import SwiftUI

/// Perfil del compañero: lo que hay cargado y lo que falta, sin presentar lo que
/// falta como un error.
struct CompanionProfileView: View {
    let companion: Companion

    @State private var isEditing = false

    var body: some View {
        List {
            Section {
                HStack(spacing: Spacing.lg) {
                    CompanionAvatar(companion: companion, size: 88)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(companion.displayName)
                            .font(AppFont.sectionTitle)

                        Text(companion.species.label)
                            .font(AppFont.secondary)
                            .foregroundStyle(Palette.inkMuted)
                    }
                }
                .padding(.vertical, Spacing.sm)
                .accessibilityElement(children: .combine)
            }

            Section {
                row(label: String(localized: "Nombre"), value: companion.name)
                row(label: String(localized: "Apodo"), value: companion.nickname)
                row(label: String(localized: "Especie"), value: companion.species.label)
                row(label: String(localized: "Raza"), value: companion.breed)
                row(label: String(localized: "Sexo"), value: companion.sex.label)
            } header: {
                Text("Datos básicos")
            }

            Section {
                row(
                    label: String(localized: "Fecha de cumpleaños"),
                    value: birthDateValue
                )
                row(label: String(localized: "Edad"), value: companion.age?.formatted)

                if let nextBirthday = companion.nextBirthday {
                    row(
                        label: String(localized: "Próximo cumpleaños"),
                        value: DateDescription.absolute(nextBirthday)
                    )
                }
            } header: {
                Text("Cumpleaños")
            }

            Section {
                row(
                    label: String(localized: "Condiciones relevantes"),
                    value: companion.relevantConditions
                )
                row(label: String(localized: "Alergias"), value: companion.allergies)
            } header: {
                Text("Salud")
            } footer: {
                Text("Esta información aparece en el modo emergencia.")
            }

            Section {
                row(
                    label: String(localized: "Veterinario de cabecera"),
                    value: veterinarianValue
                )
                row(
                    label: String(localized: "Persona responsable"),
                    value: responsiblePersonValue
                )

                NavigationLink {
                    CompanionContactsView(companion: companion)
                } label: {
                    Label {
                        Text("Editar contactos")
                    } icon: {
                        Image(systemName: "person.crop.circle")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
            } header: {
                Text("Contactos")
            } footer: {
                Text("Son los teléfonos a los que se puede llamar desde el modo emergencia.")
            }
        }
        .navigationTitle(Text("Perfil"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditing = true
                } label: {
                    Text("Editar")
                }
                .accessibilityHint(Text("Editar los datos de \(companion.displayName)"))
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                CompanionFormView(mode: .edit(companion))
            }
        }
    }

    private var veterinarianValue: String? {
        let profile = EmergencyProfileBuilder.profile(for: companion)
        guard let veterinarian = profile.veterinarian else { return nil }

        return [veterinarian.name, veterinarian.phone]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private var responsiblePersonValue: String? {
        let profile = EmergencyProfileBuilder.profile(for: companion)
        guard let person = profile.responsiblePerson else { return nil }

        return [person.name, person.phone]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private var birthDateValue: String? {
        guard let birthDate = companion.birthDate else { return nil }

        let formatted = DateDescription.absolute(birthDate)

        return companion.birthDatePrecision.isApproximate
            ? String(localized: "\(formatted) (aproximada)")
            : formatted
    }

    /// Un dato sin cargar no es un error: se muestra como una invitación, no
    /// como un campo vacío ni como una advertencia.
    private func row(label: String, value: String?) -> some View {
        let hasValue = !(value ?? "").isEmpty
        let displayValue = hasValue
            ? (value ?? "")
            : String(localized: "Podés completarlo cuando quieras")

        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(AppFont.caption)
                .foregroundStyle(Palette.inkMuted)

            Text(displayValue)
                .font(AppFont.body)
                .foregroundStyle(hasValue ? Palette.ink : Palette.inkMuted)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(label): \(displayValue)"))
    }
}
