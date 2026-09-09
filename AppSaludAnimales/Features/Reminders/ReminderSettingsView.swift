import SwiftData
import SwiftUI
import UserNotifications

/// Qué te va a avisar la app, y nada más que eso.
///
/// No hay una lista de tipos abstractos: se listan los registros reales que
/// pueden avisar, con su interruptor. Así se entiende de una qué va a sonar.
struct ReminderSettingsView: View {
    let companion: Companion

    @Environment(\.modelContext) private var modelContext

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRequestingPermission = false
    @State private var scheduled: [ScheduledReminder] = []

    private var medications: [Medication] {
        companion.activeMedications().sorted { $0.name < $1.name }
    }

    private var vaccinations: [Vaccination] {
        companion.vaccinations
            .filter { ($0.nextDueDate ?? .distantPast) > Date() }
            .sorted { ($0.nextDueDate ?? .distantPast) < ($1.nextDueDate ?? .distantPast) }
    }

    private var appointments: [Appointment] {
        companion.appointments
            .filter { $0.date > Date() }
            .sorted { $0.date < $1.date }
    }

    private var hasAnythingToRemind: Bool {
        !medications.isEmpty || !vaccinations.isEmpty || !appointments.isEmpty
    }

    var body: some View {
        List {
            permissionSection
            scheduledSection

            if !medications.isEmpty {
                Section {
                    ForEach(medications) { medication in
                        Toggle(isOn: binding(for: medication)) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(medication.name)
                                Text(reminderDescription(for: medication))
                                    .font(AppFont.caption)
                                    .foregroundStyle(Palette.inkMuted)
                            }
                        }
                    }
                } header: {
                    Text("Medicaciones")
                } footer: {
                    Text("El aviso llega con un botón para registrar la toma sin abrir la app.")
                }
            }

            if !vaccinations.isEmpty {
                Section {
                    ForEach(vaccinations) { vaccination in
                        Toggle(isOn: binding(for: vaccination)) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(vaccination.name)
                                if let dueDate = vaccination.nextDueDate {
                                    Text(String(localized: "Avisa el día anterior a \(DateDescription.absolute(dueDate))"))
                                        .font(AppFont.caption)
                                        .foregroundStyle(Palette.inkMuted)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Vacunas")
                }
            }

            if !appointments.isEmpty {
                Section {
                    ForEach(appointments) { appointment in
                        Toggle(isOn: binding(for: appointment)) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(appointment.title)
                                Text(DateDescription.absolute(appointment.date))
                                    .font(AppFont.caption)
                                    .foregroundStyle(Palette.inkMuted)
                            }
                        }
                    }
                } header: {
                    Text("Turnos")
                }
            }

            if !hasAnythingToRemind {
                Section {
                    Text("Todavía no hay nada que pueda avisarte. Cuando cargues una medicación, una vacuna con próxima fecha o un turno, aparecen acá.")
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)
                }
            }
        }
        .navigationTitle(Text("Recordatorios"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshStatus() }
    }

    // MARK: - Permiso

    @ViewBuilder
    /// Lo que el sistema tiene programado de verdad.
    ///
    /// Un aviso que no llega no deja rastro: no se puede saber si nunca se
    /// programó, si se programó mal o si el sistema lo descartó. Con esta lista
    /// se puede mirar en vez de adivinar, y sirve igual sin ningún problema:
    /// saber qué te va a avisar la app, y cuándo, es información que
    /// corresponde tener.
    private var scheduledSection: some View {
        Section {
            if scheduled.isEmpty {
                SectionEmptyState(
                    message: String(localized: "No hay ningún aviso programado. Si activaste alguno y no aparece acá, es que no llegó a programarse.")
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else {
                ForEach(scheduled) { reminder in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(reminder.title)
                            .font(AppFont.body)
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(reminder.body)
                            .font(AppFont.caption)
                            .foregroundStyle(Palette.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)

                        if let nextDate = reminder.nextDate {
                            Text(nextDate.formatted(date: .abbreviated, time: .shortened))
                                .font(AppFont.caption)
                                .foregroundStyle(Palette.inkMuted)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                    .accessibilityElement(children: .combine)
                }
            }
        } header: {
            Text("Lo que está programado")
        } footer: {
            Text("Son los avisos que el teléfono tiene guardados ahora mismo. Se rearman solos cada vez que guardás algo.")
        }
        .task { scheduled = await ReminderScheduler.shared.scheduled() }
    }

    private var permissionSection: some View {
        Section {
            switch authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                Label {
                    Text("Los avisos están activados")
                } icon: {
                    Image(systemName: "checkmark.circle")
                }
                .foregroundStyle(StatusTone.positive.content)

            case .denied:
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Los avisos están desactivados para esta app.")
                    Text("Podés activarlos desde Ajustes del teléfono, en Notificaciones.")
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.inkMuted)
                }

            default:
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Para avisarte, la app necesita tu permiso.")

                    PrimaryButton(
                        title: String(localized: "Activar los avisos"),
                        symbolName: "bell",
                        isEnabled: !isRequestingPermission
                    ) {
                        Task { await requestPermission() }
                    }
                }
                .padding(.vertical, Spacing.xs)
            }
        } header: {
            Text("Permiso")
        }
    }

    private func refreshStatus() async {
        authorizationStatus = await ReminderScheduler.shared.authorizationStatus()
    }

    private func requestPermission() async {
        isRequestingPermission = true
        _ = await ReminderScheduler.shared.requestAuthorization()
        await refreshStatus()
        await syncReminders()
        isRequestingPermission = false
    }

    // MARK: - Interruptores

    private func binding(for medication: Medication) -> Binding<Bool> {
        Binding(
            get: { medication.reminderEnabled },
            set: { medication.reminderEnabled = $0; persist() }
        )
    }

    private func binding(for vaccination: Vaccination) -> Binding<Bool> {
        Binding(
            get: { vaccination.reminderEnabled },
            set: { vaccination.reminderEnabled = $0; persist() }
        )
    }

    private func binding(for appointment: Appointment) -> Binding<Bool> {
        Binding(
            get: { appointment.reminderEnabled },
            set: { appointment.reminderEnabled = $0; persist() }
        )
    }

    private func persist() {
        try? modelContext.save()
        Task { await syncReminders() }
    }

    private func syncReminders() async {
        let companions = (try? modelContext.fetch(FetchDescriptor<Companion>())) ?? [companion]
        await ReminderScheduler.shared.sync(companions: companions)
    }

    private func reminderDescription(for medication: Medication) -> String {
        let moments = medication.timesOfDay.filter { $0 != .asNeeded }

        guard !moments.isEmpty || !medication.exactTimes.isEmpty else {
            return String(localized: "Sin horario cargado, no puede avisarte")
        }

        guard medication.exactTimes.isEmpty else {
            return String(localized: "Avisa a los horarios cargados")
        }

        return String(localized: "Avisa: \(moments.map(\.label).joined(separator: ", "))")
    }
}
