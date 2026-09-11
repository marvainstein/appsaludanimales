import SwiftData
import SwiftUI

/// Perfil del compañero: lo que hay cargado y lo que falta, sin presentar lo que
/// falta como un error.
struct CompanionProfileView: View {
    let companion: Companion

    @Environment(\.modelContext) private var modelContext

    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var isMarkingFarewell = false
    @State private var isConfirmingDeletion = false
    @State private var deletionFailed = false

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
                        Text("Cruzó el arcoíris")
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
                        .foregroundStyle(Palette.inkMuted)
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
                    .foregroundStyle(Palette.inkMuted)
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
                    .foregroundStyle(Palette.inkMuted)
            }

            Section {
                row(
                    label: String(localized: "Condiciones relevantes"),
                    value: companion.relevantConditions
                )
                row(label: String(localized: "Alergias"), value: companion.allergies)

                // El peso es un dato de salud, no un ajuste de la app. Estaba
                // entre el respaldo y el resumen, que son herramientas.
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
                .accessibilityIdentifier("profile.weight")
            } header: {
                Text("Salud")
                    .foregroundStyle(Palette.inkMuted)
            } footer: {
                Text("Esta información aparece en el modo emergencia.")
                    .foregroundStyle(Palette.inkMuted)
            }

            Section {
                row(
                    label: String(localized: "Veterinaria de cabecera"),
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
                    VeterinariansView(companion: companion)
                } label: {
                    Label {
                        Text("Veterinarias")
                    } icon: {
                        Image(systemName: "cross.case")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
                .accessibilityIdentifier("profile.veterinarians")

                NavigationLink {
                    CompanionContactsView(companion: companion)
                } label: {
                    Label {
                        Text("Personas a cargo")
                    } icon: {
                        Image(systemName: "person.crop.circle")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
            } header: {
                Text("Contactos")
                    .foregroundStyle(Palette.inkMuted)
            } footer: {
                Text("Son los teléfonos a los que se puede llamar desde el modo emergencia.")
                    .foregroundStyle(Palette.inkMuted)
            }

            Section {
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
                .accessibilityIdentifier("profile.backup")

            } footer: {
                Text("Qué te avisa la app, cómo llevar la información al veterinario, y cómo no perderla.")
                    .foregroundStyle(Palette.inkMuted)
            }

            Section {
                if companion.isPresent {
                    Button {
                        isMarkingFarewell = true
                    } label: {
                        Label {
                            Text("Marcar que cruzó el arcoíris")
                        } icon: {
                            Image(systemName: "leaf")
                        }
                        .frame(minHeight: Spacing.minimumTapTarget)
                    }
                    .accessibilityIdentifier("profile.farewell")
                } else {
                    Button {
                        undoFarewell()
                    } label: {
                        Label {
                            Text("Deshacer esta marca")
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
                    .foregroundStyle(Palette.inkMuted)
            }

            Section {
                Button(role: .destructive) {
                    isConfirmingDeletion = true
                } label: {
                    Label {
                        Text("Eliminar de la app")
                    } icon: {
                        Image(systemName: "trash")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
                .accessibilityIdentifier("companion.delete")
            } footer: {
                // Eliminar y "cruzó el arcoíris" son dos cosas distintas y es
                // fácil confundirlas en el peor momento. Acá se aclara cuál es
                // cuál, en el lugar donde alguien podría equivocarse.
                Text("Es para el que se cargó por error o el que ya no cuidás. Borra todo lo que anotaste y no se puede deshacer. Si lo que pasó es que se fue, marcá que cruzó el arcoíris: así queda todo guardado.")
                    .foregroundStyle(Palette.inkMuted)
            }

            // Lo único de esta pantalla que no habla del animal sino de la app.
            // Estaba mezclado entre el respaldo y el resumen, y con dos o tres
            // compañeros cargados aparecía repetido en cada perfil como si
            // fuera parte de la ficha de cada uno.
            Section {
                NavigationLink {
                    AboutView()
                } label: {
                    Label {
                        Text("Acerca de Estela")
                    } icon: {
                        Image(systemName: "info.circle")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
                .accessibilityIdentifier("profile.about")
            } header: {
                Text("La app")
                    .foregroundStyle(Palette.inkMuted)
            }
        }
        .navigationTitle(Text("Perfil"))
        .navigationBarTitleDisplayMode(.inline)
        // Barra opaca: translúcida, el texto de sus botones se lee sobre lo que
        // pase por detrás, que puede ser cualquier cosa.
        .toolbarBackground(.visible, for: .navigationBar)
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
        .confirmationDialog(
            Text("¿Eliminamos a \(companion.displayName)?"),
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive, action: delete)
            Button("Mejor no", role: .cancel) {}
        } message: {
            Text(CompanionDeletion.warningMessage(
                name: companion.displayName,
                recordCount: HistoryBuilder.entries(for: companion).count
            ))
        }
        .alert(
            Text("No pudimos eliminar"),
            isPresented: $deletionFailed
        ) {
            Button("Entendido", role: .cancel) { deletionFailed = false }
        } message: {
            Text("Sigue todo guardado. Podés intentar de nuevo en un momento.")
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

    private func delete() {
        modelContext.delete(companion)

        do {
            try modelContext.save()
            // Sus avisos se van con él.
            ReminderSync.refresh(using: modelContext)
            dismiss()
        } catch {
            deletionFailed = true
        }
    }

    private func undoFarewell() {
        companion.farewellDate = nil
        try? modelContext.save()
        ReminderSync.refresh(using: modelContext)
    }

    /// La de cabecera es la que aparece acá. Las demás viven en su pantalla,
    /// que es donde se cargan y se cambian.
    private var veterinarianValue: String? {
        let profile = EmergencyProfileBuilder.profile(for: companion)
        guard let veterinarian = profile.veterinarians.first else { return nil }

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
