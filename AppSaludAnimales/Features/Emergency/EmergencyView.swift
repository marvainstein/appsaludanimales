import SwiftUI

/// Modo emergencia.
///
/// Se diseña para el peor momento: alguien asustado, apurado, que necesita
/// contar en voz alta qué toma su compañero y llamar a un veterinario. Por eso
/// no hay navegación, el texto es más grande que en el resto de la app, y las
/// dos acciones que importan —llamar— están a un toque.
struct EmergencyView: View {
    let companion: Companion

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var profile: EmergencyProfile {
        EmergencyProfileBuilder.profile(for: companion)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    identity
                    criticalInformation
                    currentCare
                    contacts
                    missingInformationNote
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Palette.background)
            .navigationTitle(Text("Emergencia"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cerrar")
                            .font(AppFont.cardTitle)
                    }
                    .accessibilityHint(Text("Vuelve a la pantalla anterior"))
                }
            }
        }
    }

    // MARK: - Quién es

    private var identity: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.lg) {
                CompanionAvatar(companion: companion, size: 96)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(profile.displayName)
                        .font(AppFont.Emergency.name)
                        .foregroundStyle(Palette.ink)

                    Text(identitySubtitle)
                        .font(AppFont.Emergency.value)
                        .foregroundStyle(Palette.inkMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(profile.displayName). \(identitySubtitle)"))
        .accessibilityAddTraits(.isHeader)
    }

    private var identitySubtitle: String {
        guard let ageText = profile.ageText else { return profile.speciesLabel }
        return "\(profile.speciesLabel) · \(ageText)"
    }

    // MARK: - Lo que puede cambiar una decisión

    private var criticalInformation: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            block(
                title: String(localized: "Alergias"),
                value: profile.allergies,
                emptyValue: String(localized: "No hay alergias registradas"),
                tone: profile.allergies == nil ? .neutral : .critical
            )

            block(
                title: String(localized: "Condiciones relevantes"),
                value: profile.conditions,
                emptyValue: String(localized: "No hay condiciones registradas"),
                tone: profile.conditions == nil ? .neutral : .attention
            )
        }
    }

    // MARK: - Lo que recibe ahora

    private var currentCare: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            list(
                title: String(localized: "Medicaciones actuales"),
                items: profile.medications,
                emptyValue: String(localized: "No recibe medicación")
            )

            list(
                title: String(localized: "Tratamientos actuales"),
                items: profile.treatments,
                emptyValue: String(localized: "No tiene tratamientos en curso")
            )
        }
    }

    // MARK: - A quién llamar

    private var contacts: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("A quién llamar")
                .font(AppFont.Emergency.sectionTitle)
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)

            if profile.veterinarians.isEmpty {
                contactCard(
                    title: String(localized: "Veterinaria"),
                    contact: nil,
                    emptyValue: String(localized: "No hay ninguna veterinaria cargada")
                )
            } else {
                ForEach(Array(profile.veterinarians.enumerated()), id: \.offset) { _, contact in
                    contactCard(
                        title: contact.isPrimary
                            ? String(localized: "Veterinaria de cabecera")
                            : String(localized: "Veterinaria"),
                        contact: contact,
                        emptyValue: String(localized: "Sin teléfono cargado")
                    )
                }
            }

            if profile.responsiblePeople.isEmpty {
                contactCard(
                    title: String(localized: "Persona a cargo"),
                    contact: nil,
                    emptyValue: String(localized: "No hay una persona a cargo cargada")
                )
            } else {
                ForEach(Array(profile.responsiblePeople.enumerated()), id: \.offset) { index, person in
                    contactCard(
                        title: profile.responsiblePeople.count > 1
                            ? String(localized: "Persona a cargo \(index + 1)")
                            : String(localized: "Persona a cargo"),
                        contact: person,
                        emptyValue: ""
                    )
                }
            }
        }
    }

    private func contactCard(
        title: String,
        contact: EmergencyContact?,
        emptyValue: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(AppFont.Emergency.label)
                .foregroundStyle(Palette.inkMuted)

            if let contact {
                Text(contact.name)
                    .font(AppFont.Emergency.value)
                    .foregroundStyle(Palette.ink)

                if let role = contact.role {
                    Text(role)
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)
                }

                if let phone = contact.phone {
                    if let url = contact.callURL {
                        Button {
                            openURL(url)
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "phone.fill")
                                    .accessibilityHidden(true)

                                Text(phone)
                            }
                            .font(AppFont.Emergency.value)
                            .frame(maxWidth: .infinity, minHeight: Spacing.minimumTapTarget * 1.2)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel(Text("Llamar a \(contact.name)"))
                        .accessibilityHint(Text("Abre la aplicación de teléfono"))
                    } else {
                        Text(phone)
                            .font(AppFont.Emergency.value)
                            .foregroundStyle(Palette.ink)
                    }
                }
            } else {
                Text(emptyValue)
                    .font(AppFont.Emergency.value)
                    .foregroundStyle(Palette.inkMuted)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Palette.separator, lineWidth: 1)
        )
    }

    // MARK: - Piezas

    private func block(
        title: String,
        value: String?,
        emptyValue: String,
        tone: StatusTone
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(AppFont.Emergency.label)
                .foregroundStyle(value == nil ? Palette.inkMuted : tone.content)

            Text(value ?? emptyValue)
                .font(AppFont.Emergency.value)
                .foregroundStyle(value == nil ? Palette.inkMuted : Palette.ink)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(value == nil ? Palette.surfaceMuted : tone.softBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title): \(value ?? emptyValue)"))
    }

    private func list(
        title: String,
        items: [String],
        emptyValue: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(AppFont.Emergency.label)
                .foregroundStyle(Palette.inkMuted)

            if items.isEmpty {
                Text(emptyValue)
                    .font(AppFont.Emergency.value)
                    .foregroundStyle(Palette.inkMuted)
            } else {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(AppFont.Emergency.value)
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Palette.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibleList(title: title, items: items, emptyValue: emptyValue)))
    }

    private func accessibleList(title: String, items: [String], emptyValue: String) -> String {
        guard !items.isEmpty else { return "\(title): \(emptyValue)" }
        return "\(title): \(items.joined(separator: ", "))"
    }

    /// Lo que falta se dice al final y en tono de invitación: en una emergencia
    /// nadie necesita que le señalen lo que no hizo.
    @ViewBuilder
    private var missingInformationNote: some View {
        let missing = profile.missingEssentials

        if !missing.isEmpty {
            Text("Para que esta pantalla sirva más, podés agregar \(missing.joined(separator: " y ")) desde el perfil de \(profile.displayName).")
                .font(AppFont.secondary)
                .foregroundStyle(Palette.inkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
