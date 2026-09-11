import SwiftUI

/// Todas las sesiones anotadas de un tratamiento, de la más nueva a la más
/// vieja.
///
/// Es donde se ve cómo cambió la frecuencia con el tiempo: Luli empezó yendo a
/// fisioterapia dos veces por semana y terminó yendo cada quince días. Esa
/// historia no está en el campo de frecuencia, que solo dice cómo es ahora.
struct TreatmentSessionsView: View {
    let treatment: Treatment

    private var days: [(date: Date, sessions: [TreatmentSession])] {
        let calendar = Calendar.current

        return Dictionary(grouping: treatment.sessions) {
            calendar.startOfDay(for: $0.attendedAt)
        }
        .map { (date: $0.key, sessions: $0.value.sorted { $0.attendedAt > $1.attendedAt }) }
        .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            if treatment.sessions.isEmpty {
                Section {
                    SectionEmptyState(
                        message: String(localized: "Todavía no anotaste ninguna sesión. Podés anotarlas desde «En curso», en la pantalla de hoy.")
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(days, id: \.date) { day in
                    Section {
                        ForEach(day.sessions) { session in
                            row(for: session)
                        }
                    } header: {
                        Text(DateDescription.absolute(day.date))
                            .foregroundStyle(Palette.inkMuted)
                    }
                }
            }
        }
        .navigationTitle(Text("Sesiones de \(treatment.name)"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func row(for session: TreatmentSession) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(ReminderPlanBuilder.time(session.attendedAt))
                .font(AppFont.cardTitle)
                .foregroundStyle(Palette.ink)

            if let quien = session.recordedByName, !quien.isEmpty {
                Text("La anotó \(quien)")
                    .font(AppFont.secondary)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(AppFont.secondary)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}
