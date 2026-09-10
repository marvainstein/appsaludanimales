import SwiftUI

/// Todas las tomas anotadas de una medicación, de la más nueva a la más vieja.
///
/// Agrupadas por día, porque así se recuerdan: "el martes le di las dos" y no
/// "la toma número 47". Y porque lo que uno viene a comprobar acá casi siempre
/// es si faltó alguna.
struct MedicationDosesView: View {
    let medication: Medication

    private var days: [(date: Date, doses: [MedicationDose])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: medication.doses) {
            calendar.startOfDay(for: $0.administeredAt)
        }

        return grouped
            .map { (date: $0.key, doses: $0.value.sorted { $0.administeredAt > $1.administeredAt }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            if medication.doses.isEmpty {
                Section {
                    SectionEmptyState(
                        message: String(localized: "Todavía no anotaste ninguna toma. Podés anotarlas desde «En curso», en la pantalla de hoy.")
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(days, id: \.date) { day in
                    Section {
                        ForEach(day.doses) { dose in
                            row(for: dose)
                        }
                    } header: {
                        Text(DateDescription.absolute(day.date))
                            .foregroundStyle(Palette.inkMuted)
                    }
                }
            }
        }
        .navigationTitle(Text("Tomas de \(medication.name)"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func row(for dose: MedicationDose) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(ReminderPlanBuilder.time(dose.administeredAt))
                .font(AppFont.cardTitle)
                .foregroundStyle(Palette.ink)

            if let quien = dose.recordedByName, !quien.isEmpty {
                Text("La anotó \(quien)")
                    .font(AppFont.secondary)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let notes = dose.notes, !notes.isEmpty {
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
