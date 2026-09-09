import SwiftData
import SwiftUI

/// Anotar un turno.
///
/// Un turno es de las pocas cosas de esta app que tienen hora exacta, y de las
/// pocas por las que conviene avisar con anticipación: llegar tarde a un turno
/// de veterinaria cuesta el turno entero.
struct AppointmentRecordView: View {
    let companion: Companion
    var onFinished: () -> Void = {}

    private let editing: Appointment?

    @Environment(\.modelContext) private var modelContext

    @State private var title: String
    @State private var date: Date
    @State private var place: String
    @State private var notes: String
    @State private var reminderEnabled: Bool
    @State private var leadTime: ReminderLeadTime
    @State private var saveErrorMessage: String?

    /// Con cuánta anticipación avisar. Son las tres que la gente usa; ofrecer
    /// diez opciones no ayuda a decidir.
    enum ReminderLeadTime: Int, CaseIterable, Identifiable {
        case oneHour = 60
        case oneDay = 1440
        case twoDays = 2880

        var id: Int { rawValue }

        var label: String {
            switch self {
            case .oneHour: String(localized: "Una hora antes")
            case .oneDay: String(localized: "El día anterior")
            case .twoDays: String(localized: "Dos días antes")
            }
        }
    }

    init(
        companion: Companion,
        editing: Appointment? = nil,
        onFinished: @escaping () -> Void = {}
    ) {
        self.companion = companion
        self.editing = editing
        self.onFinished = onFinished
        _title = State(initialValue: editing?.title ?? "")
        _date = State(initialValue: editing?.date ?? Date())
        _place = State(initialValue: editing?.place ?? "")
        _notes = State(initialValue: editing?.notes ?? "")
        _reminderEnabled = State(initialValue: editing?.reminderEnabled ?? true)
        _leadTime = State(
            initialValue: ReminderLeadTime(rawValue: editing?.reminderLeadTimeMinutes ?? 1440) ?? .oneDay
        )
    }

    /// Si el aviso caería antes de ahora, no hay nada que programar.
    private var reminderIsInThePast: Bool {
        guard reminderEnabled else { return false }

        let fireDate = date.addingTimeInterval(-Double(leadTime.rawValue) * 60)
        return fireDate <= Date()
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section {
                LabeledTextField(
                    label: String(localized: "Para qué es"),
                    text: $title,
                    hint: String(localized: "Por ejemplo: control anual, radiografía de cadera."),
                    isRequired: true,
                    autocapitalization: .sentences
                )

                DatePicker(selection: $date, displayedComponents: [.date, .hourAndMinute]) {
                    Text("Cuándo")
                }

                LabeledTextField(
                    label: String(localized: "Dónde"),
                    text: $place,
                    autocapitalization: .words
                )
            } header: {
                Text("Turno")
            }

            Section {
                Toggle(isOn: $reminderEnabled) {
                    Text("Avisarme antes")
                }

                if reminderEnabled {
                    Picker(selection: $leadTime) {
                        ForEach(ReminderLeadTime.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    } label: {
                        Text("Con cuánta anticipación")
                    }
                }

                LabeledTextField(
                    label: String(localized: "Notas"),
                    text: $notes
                )
            } header: {
                Text("Aviso")
            } footer: {
                // La app descartaba en silencio un aviso cuya hora ya había
                // pasado, y quedaba la sensación de que los recordatorios no
                // funcionan. Decirlo cuesta una línea.
                Text(reminderIsInThePast
                    ? "Con esa anticipación el aviso caería antes de ahora, así que no va a llegar. Elegí una anticipación menor si querés que suene."
                    : "El turno aparece en Próximamente cuando se acerque, avises o no.")
            }

            PrimaryButtonSection(
                title: editing == nil
                    ? String(localized: "Guardar el turno")
                    : String(localized: "Guardar los cambios"),
                hint: canSave ? nil : String(localized: "Escribí para qué es el turno para poder guardarlo"),
                isEnabled: canSave,
                action: save
            )
        }
        .navigationTitle(Text(editing == nil
            ? String(localized: "Turno")
            : String(localized: "Editar el turno")))
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
        let appointment = editing ?? Appointment(date: date)

        appointment.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.date = date
        appointment.place = optional(place)
        appointment.notes = optional(notes)
        appointment.reminderEnabled = reminderEnabled
        appointment.reminderLeadTimeMinutes = leadTime.rawValue

        if editing == nil {
            companion.appointments.append(appointment)
        }

        do {
            try modelContext.save()
            ReminderSync.refresh(using: modelContext)
            onFinished()
        } catch {
            saveErrorMessage = String(localized: "El turno no se guardó. Podés intentar de nuevo en un momento.")
        }
    }

    private func optional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
