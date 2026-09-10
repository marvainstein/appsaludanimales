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
    @State private var isEditing = false
    @State private var isAttachingDocument = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(entry.category.label)
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.inkMuted)

                    Text(currentTitle)
                        .font(AppFont.sectionTitle)
                        .fixedSize(horizontal: false, vertical: true)

                    if let badge = currentBadge {
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
                        .foregroundStyle(Palette.inkMuted)
                }
            }

            if let attachment {
                attachedDocumentsSection(for: attachment)
            }

            Section {
                ForEach(fields, id: \.label) { field in
                    row(label: field.label, value: field.value)
                }
            } header: {
                Text("Detalles")
                    .foregroundStyle(Palette.inkMuted)
            }

            dosesSection

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
                        .foregroundStyle(Palette.inkMuted)
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
                    .foregroundStyle(Palette.inkMuted)
            }
        }
        .navigationTitle(Text(entry.category.label))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEditable {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isEditing = true
                    } label: {
                        Text("Editar")
                    }
                    .accessibilityHint(Text("Abre el registro para corregir lo que cargaste"))
                    .accessibilityIdentifier("record.edit")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            editSheet
        }
        .sheet(isPresented: $isAttachingDocument) {
            if let attachment {
                NavigationStack {
                    DocumentRecordView(
                        companion: companion,
                        attachment: attachment,
                        onFinished: { isAttachingDocument = false }
                    )
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                isAttachingDocument = false
                            } label: {
                                Text("Cancelar")
                            }
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            Text("¿Eliminamos este registro?"),
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive, action: delete)
            Button("Mejor no", role: .cancel) {}
        } message: {
            Text("“\(currentTitle)” deja de aparecer en la historia de \(companion.displayName).")
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

    // MARK: - Documentos adjuntos

    /// Solo los episodios y los turnos llevan documentos colgados. Al resto no
    /// les corresponde: una nota con un estudio adjunto es un documento, y hay
    /// una pantalla para eso.
    private var attachment: DocumentAttachment? {
        switch entry.reference {
        case let .episode(episode): .episode(episode)
        case let .appointment(appointment): .appointment(appointment)
        default: nil
        }
    }

    private var attachedDocuments: [HealthDocument] {
        let documents: [HealthDocument]

        switch entry.reference {
        case let .episode(episode): documents = episode.documents
        case let .appointment(appointment): documents = appointment.documents
        default: documents = []
        }

        return documents.sorted { $0.date > $1.date }
    }

    private func attachedDocumentsSection(for attachment: DocumentAttachment) -> some View {
        Section {
            ForEach(attachedDocuments) { document in
                NavigationLink {
                    HealthRecordDetailView(
                        companion: companion,
                        entry: HistoryEntry(
                            id: document.id,
                            title: document.title,
                            detail: document.category,
                            date: document.date,
                            category: .document,
                            badge: nil,
                            reference: .document(document)
                        )
                    )
                } label: {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(document.title)
                            .font(AppFont.body)
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(DateDescription.absolute(document.date))
                            .font(AppFont.caption)
                            .foregroundStyle(Palette.inkMuted)
                    }
                    .padding(.vertical, Spacing.xs)
                }
                .accessibilityElement(children: .combine)
            }

            Button {
                isAttachingDocument = true
            } label: {
                Label {
                    Text("Adjuntar un documento")
                } icon: {
                    Image(systemName: "paperclip")
                }
                .frame(minHeight: Spacing.minimumTapTarget)
            }
            .accessibilityIdentifier("record.attachDocument")
        } header: {
            Text("Documentos")
                .foregroundStyle(Palette.inkMuted)
        } footer: {
            Text(attachedDocuments.isEmpty
                ? "Un estudio, una receta o una foto de lo que pasó. Queda enganchado acá y también en el historial."
                : "Aparecen acá y también en el historial, con el resto de los documentos.")
                .foregroundStyle(Palette.inkMuted)
        }
    }

    // MARK: - Editar

    /// Se edita lo que se puede cargar desde la app, que ahora es todo salvo
    /// las mediciones que no son de peso, porque todavía no existen.
    // MARK: - Las tomas

    /// Las dos últimas, y el acceso a todas.
    ///
    /// Dos y no una: lo que uno viene a comprobar es si ya se dio la de hoy, y
    /// para eso hace falta ver la anterior. Y no todas, porque una medicación de
    /// años son cientos de renglones tapando el resto de la ficha.
    @ViewBuilder
    private var dosesSection: some View {
        if case let .medication(medication) = entry.reference {
            Section {
                if medication.doses.isEmpty {
                    Text("Todavía no anotaste ninguna. Se anotan desde «En curso», en la pantalla de hoy.")
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(latestDoses(of: medication)) { dose in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(DateDescription.absolute(dose.administeredAt))
                                .font(AppFont.body)
                                .foregroundStyle(Palette.ink)

                            Text(dose.dose.map { "\(ReminderPlanBuilder.time(dose.administeredAt)) · \($0)" }
                                ?? ReminderPlanBuilder.time(dose.administeredAt))
                                .font(AppFont.secondary)
                                .foregroundStyle(Palette.inkMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, Spacing.xs)
                        .accessibilityElement(children: .combine)
                    }

                    NavigationLink {
                        MedicationDosesView(medication: medication)
                    } label: {
                        Label {
                            Text("Ver todas las tomas")
                        } icon: {
                            Image(systemName: "list.bullet")
                        }
                        .frame(minHeight: Spacing.minimumTapTarget)
                    }
                    .accessibilityIdentifier("record.allDoses")
                }
            } header: {
                Text(medication.doses.isEmpty
                    ? String(localized: "Tomas")
                    : String(localized: "Tomas · \(medication.doses.count)"))
                    .foregroundStyle(Palette.inkMuted)
            }
        }
    }

    private func latestDoses(of medication: Medication) -> [MedicationDose] {
        Array(medication.doses.sorted { $0.administeredAt > $1.administeredAt }.prefix(2))
    }

    private var isEditable: Bool {
        switch entry.reference {
        case .medication, .vaccination, .episode, .document, .note, .treatment, .appointment: true
        case let .measurement(measurement): measurement.kind == .weight
        }
    }

    private var editSheet: some View {
        NavigationStack {
            editForm
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isEditing = false
                        } label: {
                            Text("Cancelar")
                        }
                    }
                }
        }
    }

    /// Editar usa el mismo formulario con el que se cargó: si el de peso cambia,
    /// cambia en los dos lados. Dos pantallas parecidas para lo mismo terminan
    /// siempre en dos comportamientos distintos.
    @ViewBuilder
    private var editForm: some View {
        switch entry.reference {
        case let .medication(medication):
            MedicationFormView(companion: companion, editing: medication, onFinished: finishEditing)

        case let .vaccination(vaccination):
            VaccinationRecordView(companion: companion, editing: vaccination, onFinished: finishEditing)

        case let .episode(episode):
            EpisodeRecordView(companion: companion, editing: episode, onFinished: finishEditing)

        case let .measurement(measurement):
            WeightRecordView(companion: companion, editing: measurement, onFinished: finishEditing)

        case let .document(document):
            DocumentRecordView(companion: companion, editing: document, onFinished: finishEditing)

        case let .note(note):
            NoteRecordView(companion: companion, editing: note, onFinished: finishEditing)

        case let .treatment(treatment):
            TreatmentRecordView(companion: companion, editing: treatment, onFinished: finishEditing)

        case let .appointment(appointment):
            AppointmentRecordView(companion: companion, editing: appointment, onFinished: finishEditing)
        }
    }

    private func finishEditing() {
        isEditing = false
    }

    // MARK: - Contenido

    /// El título, la fecha y el estado se leen del registro real y no de la
    /// línea del historial con la que se llegó hasta acá. Esa línea es una foto
    /// del momento en que se armó la lista: después de editar el registro —o de
    /// cambiarle el estado desde esta misma pantalla— mostraría lo viejo.
    private var currentTitle: String {
        switch entry.reference {
        case let .medication(medication): medication.name
        case let .treatment(treatment): treatment.name
        case let .vaccination(vaccination): vaccination.name
        case let .episode(episode): episode.symptom
        case let .measurement(measurement): measurement.formattedValue
        case let .appointment(appointment): appointment.title
        case let .document(document): document.title
        case let .note(note): note.text
        }
    }

    private var currentDate: Date {
        switch entry.reference {
        case let .medication(medication): medication.startDate
        case let .treatment(treatment): treatment.startDate
        case let .vaccination(vaccination): vaccination.date
        case let .episode(episode): episode.date
        case let .measurement(measurement): measurement.date
        case let .appointment(appointment): appointment.date
        case let .document(document): document.date
        case let .note(note): note.date
        }
    }

    private var currentBadge: StatusBadge? {
        switch entry.reference {
        case let .medication(medication): medication.status().badge
        case let .treatment(treatment): treatment.status().badge
        case let .episode(episode): episode.status.badge
        default: nil
        }
    }

    private struct Field {
        let label: String
        let value: String?
    }

    private struct StateAction {
        let title: String
        let symbolName: String
        let perform: () -> Void
    }

    /// Para lo que dura en el tiempo, esa fecha es cuándo empezó, y decir
    /// solamente "Fecha" al lado de un "Termina" no se entiende. Para lo que
    /// pasó una vez —una vacuna, un estudio, un peso— es la fecha y nada más.
    private var dateLabel: String {
        switch entry.reference {
        case .medication, .treatment:
            String(localized: "Fecha de inicio")
        case .vaccination, .episode, .document, .note, .appointment, .measurement:
            String(localized: "Fecha")
        }
    }

    private var fields: [Field] {
        var fields: [Field] = [
            Field(label: dateLabel, value: DateDescription.absolute(currentDate))
        ]

        switch entry.reference {
        case let .medication(medication):
            fields.append(Field(label: String(localized: "Dosis"), value: medication.dose))
            fields.append(Field(
                label: String(localized: "Cuándo se administra"),
                value: MedicationSchedule.description(for: medication)
            ))
            fields.append(Field(
                label: String(localized: "Termina"),
                value: medication.endDate.map { DateDescription.absolute($0) }
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
        // Suspender o finalizar también apaga sus avisos.
        ReminderSync.refresh(using: modelContext)
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
            // Un aviso de una medicación eliminada sigue sonando hasta la
            // próxima vez que se abre la app. Se cancela ahora.
            ReminderSync.refresh(using: modelContext)
            dismiss()
        } catch {
            deletionFailed = true
        }
    }
}
