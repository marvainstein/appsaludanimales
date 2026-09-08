import SwiftData
import SwiftUI

/// Detalle de un registro: todo lo que se guardó, las acciones que cambian su
/// estado, y la posibilidad de eliminarlo.
///
/// Poder deshacer lo registrado no es una función más: si algo se anota mal y no
/// hay forma de arreglarlo, la próxima vez se anota con miedo.
struct HealthRecordDetailView: View {
    let companion: Companion
    let entry: HistoryEntry

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isConfirmingDeletion = false
    @State private var deletionFailed = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(entry.category.label)
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.inkMuted)

                    Text(entry.title)
                        .font(AppFont.sectionTitle)

                    if let badge = entry.badge {
                        StatusChip(status: badge)
                    }
                }
                .padding(.vertical, Spacing.xs)
                .accessibilityElement(children: .combine)
            }

            if case let .document(document) = entry.reference {
                Section {
                    DocumentPreview(document: document, companionName: companion.displayName)
                } header: {
                    Text("Archivo")
                }
            }

            Section {
                ForEach(fields, id: \.label) { field in
                    row(label: field.label, value: field.value)
                }
            } header: {
                Text("Detalles")
            }

            if !stateActions.isEmpty {
                Section {
                    ForEach(stateActions, id: \.title) { action in
                        Button(action: action.perform) {
                            Label {
                                Text(action.title)
                            } icon: {
                                Image(systemName: action.symbolName)
                            }
                            .frame(minHeight: Spacing.minimumTapTarget)
                        }
                    }
                } header: {
                    Text("Acciones")
                }
            }

            Section {
                Button(role: .destructive) {
                    isConfirmingDeletion = true
                } label: {
                    Label {
                        Text("Eliminar este registro")
                    } icon: {
                        Image(systemName: "trash")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
            } footer: {
                Text("Se elimina solo de la historia de \(companion.displayName). No se puede deshacer.")
            }
        }
        .navigationTitle(Text(entry.category.label))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            Text("¿Eliminamos este registro?"),
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive, action: delete)
            Button("Mejor no", role: .cancel) {}
        } message: {
            Text("“\(entry.title)” deja de aparecer en la historia de \(companion.displayName).")
        }
        .alert(
            Text("No pudimos eliminar"),
            isPresented: $deletionFailed
        ) {
            Button("Entendido", role: .cancel) { deletionFailed = false }
        } message: {
            Text("El registro sigue guardado. Podés intentar de nuevo en un momento.")
        }
    }

    // MARK: - Contenido

    private struct Field {
        let label: String
        let value: String?
    }

    private struct StateAction {
        let title: String
        let symbolName: String
        let perform: () -> Void
    }

    private var fields: [Field] {
        var fields: [Field] = [
            Field(label: String(localized: "Fecha"), value: DateDescription.absolute(entry.date))
        ]

        switch entry.reference {
        case let .medication(medication):
            fields.append(Field(label: String(localized: "Dosis"), value: medication.dose))
            fields.append(Field(
                label: String(localized: "Cuándo se administra"),
                value: medication.timesOfDay.isEmpty
                    ? nil
                    : medication.timesOfDay.map(\.label).joined(separator: ", ")
            ))
            fields.append(Field(
                label: String(localized: "Termina"),
                value: medication.endDate.map { DateDescription.absolute($0) }
            ))
            fields.append(Field(
                label: String(localized: "Tomas registradas"),
                value: medication.doses.isEmpty ? nil : medication.doses.count.formatted()
            ))
            fields.append(Field(label: String(localized: "Indicaciones"), value: medication.indications))

        case let .treatment(treatment):
            fields.append(Field(label: String(localized: "Categoría"), value: treatment.category))
            fields.append(Field(label: String(localized: "Frecuencia"), value: treatment.frequency))
            fields.append(Field(label: String(localized: "Lugar"), value: treatment.place))
            fields.append(Field(
                label: String(localized: "Termina"),
                value: treatment.endDate.map { DateDescription.absolute($0) }
            ))
            fields.append(Field(label: String(localized: "Notas"), value: treatment.notes))

        case let .vaccination(vaccination):
            fields.append(Field(
                label: String(localized: "Próxima aplicación"),
                value: vaccination.nextDueDate.map { DateDescription.absolute($0) }
            ))
            fields.append(Field(label: String(localized: "Observaciones"), value: vaccination.notes))

        case let .episode(episode):
            fields.append(Field(label: String(localized: "Descripción"), value: episode.episodeDescription))
            fields.append(Field(label: String(localized: "Intensidad"), value: episode.intensity?.label))
            fields.append(Field(label: String(localized: "Duración"), value: episode.durationDescription))
            fields.append(Field(
                label: String(localized: "Se resolvió"),
                value: episode.resolvedAt.map { DateDescription.absolute($0) }
            ))
            fields.append(Field(label: String(localized: "Notas"), value: episode.notes))

        case let .measurement(measurement):
            fields.append(Field(label: String(localized: "Valor"), value: measurement.formattedValue))
            fields.append(Field(label: String(localized: "Notas"), value: measurement.notes))

        case let .appointment(appointment):
            fields.append(Field(label: String(localized: "Lugar"), value: appointment.place))
            fields.append(Field(label: String(localized: "Notas"), value: appointment.notes))

        case let .document(document):
            fields.append(Field(label: String(localized: "Categoría"), value: document.category))
            fields.append(Field(label: String(localized: "Archivo"), value: document.fileName))
            fields.append(Field(label: String(localized: "Notas"), value: document.notes))

        case .note:
            break
        }

        return fields
    }

    private var stateActions: [StateAction] {
        switch entry.reference {
        case let .medication(medication):
            return activityActions(
                isSuspended: medication.isSuspended,
                hasEnded: medication.endDate.map { $0 < Date() } ?? false,
                suspend: { medication.isSuspended = true },
                resume: { medication.isSuspended = false },
                finish: { medication.endDate = Date() }
            )

        case let .treatment(treatment):
            return activityActions(
                isSuspended: treatment.isSuspended,
                hasEnded: treatment.endDate.map { $0 < Date() } ?? false,
                suspend: { treatment.isSuspended = true },
                resume: { treatment.isSuspended = false },
                finish: { treatment.endDate = Date() }
            )

        case let .episode(episode):
            return EpisodeStatus.allCases
                .filter { $0 != episode.status }
                .map { status in
                    StateAction(
                        title: episodeActionTitle(for: status),
                        symbolName: status.symbolName,
                        perform: { apply { episode.status = status } }
                    )
                }

        default:
            return []
        }
    }

    private func activityActions(
        isSuspended: Bool,
        hasEnded: Bool,
        suspend: @escaping () -> Void,
        resume: @escaping () -> Void,
        finish: @escaping () -> Void
    ) -> [StateAction] {
        guard !hasEnded else { return [] }

        var actions: [StateAction] = []

        if isSuspended {
            actions.append(StateAction(
                title: String(localized: "Retomar"),
                symbolName: "play.circle",
                perform: { apply(resume) }
            ))
        } else {
            actions.append(StateAction(
                title: String(localized: "Suspender por ahora"),
                symbolName: "pause.circle",
                perform: { apply(suspend) }
            ))
        }

        actions.append(StateAction(
            title: String(localized: "Marcar como finalizado"),
            symbolName: "checkmark.circle",
            perform: { apply(finish) }
        ))

        return actions
    }

    private func episodeActionTitle(for status: EpisodeStatus) -> String {
        switch status {
        case .active: String(localized: "Marcar como activo")
        case .monitoring: String(localized: "Marcar en seguimiento")
        case .resolved: String(localized: "Marcar como resuelto")
        }
    }

    /// Un dato sin cargar se ofrece como invitación, no como un campo vacío.
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

    // MARK: - Acciones

    private func apply(_ change: () -> Void) {
        change()
        try? modelContext.save()
    }

    private func delete() {
        switch entry.reference {
        case let .medication(medication): modelContext.delete(medication)
        case let .treatment(treatment): modelContext.delete(treatment)
        case let .vaccination(vaccination): modelContext.delete(vaccination)
        case let .episode(episode): modelContext.delete(episode)
        case let .measurement(measurement): modelContext.delete(measurement)
        case let .appointment(appointment): modelContext.delete(appointment)
        case let .document(document): modelContext.delete(document)
        case let .note(note): modelContext.delete(note)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            deletionFailed = true
        }
    }
}
