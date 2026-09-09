import SwiftData
import SwiftUI

/// Perfil del compañero: lo que hay cargado y lo que falta, sin presentar lo que
/// falta como un error.
struct CompanionProfileView: View {
    let companion: Companion

    @Environment(\.modelContext) private var modelContext

    @State private var isEditing = false
    @State private var isMarkingFarewell = false

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

            if let farewell = companion.farewellDate {
                Section {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Ya no está con nosotros")
                            .font(AppFont.cardTitle)
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(DateDescription.absolute(farewell))
                            .font(AppFont.body)
                            .foregroundStyle(Palette.inkMuted)
                    }
                    .padding(.vertical, Spacing.xs)
                    .accessibilityElement(children: .combine)
                } footer: {
                    Text("Su historia queda guardada entera. La app no te pide nada más por \(companion.displayName).")
                }
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
                ForEach(Array(responsiblePeopleValues.enumerated()), id: \.offset) { index, value in
                    row(
                        label: responsiblePeopleValues.count > 1
                            ? String(localized: "Persona a cargo \(index + 1)")
                            : String(localized: "Persona a cargo"),
                        value: value
                    )
                }

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

            Section {
                NavigationLink {
                    WeightChartView(companion: companion)
                } label: {
                    Label {
                        Text("Evolución del peso")
                    } icon: {
                        Image(systemName: "chart.xyaxis.line")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }

                NavigationLink {
                    ReminderSettingsView(companion: companion)
                } label: {
                    Label {
                        Text("Recordatorios")
                    } icon: {
                        Image(systemName: "bell")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }

                NavigationLink {
                    ExportReportView(companion: companion)
                } label: {
                    Label {
                        Text("Resumen en PDF")
                    } icon: {
                        Image(systemName: "doc.richtext")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }

                NavigationLink {
                    BackupView()
                } label: {
                    Label {
                        Text("Respaldo")
                    } icon: {
                        Image(systemName: "externaldrive")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
            } footer: {
                Text("Qué te avisa la app, cómo llevar la información al veterinario, y cómo no perderla.")
            }

            Section {
                if companion.isPresent {
                    Button {
                        isMarkingFarewell = true
                    } label: {
                        Label {
                            Text("Marcar que ya no está")
                        } icon: {
                            Image(systemName: "leaf")
                        }
                        .frame(minHeight: Spacing.minimumTapTarget)
                    }
                } else {
                    Button {
                        undoFarewell()
                    } label: {
                        Label {
                            Text("Marcar que sí está")
                        } icon: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .frame(minHeight: Spacing.minimumTapTarget)
                    }
                }
            } footer: {
                Text(companion.isPresent
                    ? "Se apagan los avisos y sale de la pantalla de todos los días. No se borra nada, y se puede deshacer."
                    : "Vuelve a aparecer en la pantalla de todos los días y se rearman los avisos que tenga cargados.")
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
        .sheet(isPresented: $isMarkingFarewell) {
            FarewellSheet(companion: companion)
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                CompanionFormView(mode: .edit(companion))
            }
        }
    }

    private func undoFarewell() {
        companion.farewellDate = nil
        try? modelContext.save()
        ReminderSync.refresh(using: modelContext)
    }

    private var veterinarianValue: String? {
        let profile = EmergencyProfileBuilder.profile(for: companion)
        guard let veterinarian = profile.veterinarian else { return nil }

        return [veterinarian.name, veterinarian.phone]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    /// Siempre al menos una fila: sin nadie cargado, la fila vacía es la que
    /// invita a cargarlo.
    private var responsiblePeopleValues: [String?] {
        let people = EmergencyProfileBuilder.profile(for: companion).responsiblePeople

        guard !people.isEmpty else { return [nil] }

        return people.map { person in
            [person.name, person.phone]
                .compactMap { $0 }
                .joined(separator: " · ")
        }
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
