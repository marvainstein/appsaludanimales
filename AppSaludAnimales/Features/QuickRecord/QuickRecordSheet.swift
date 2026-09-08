import SwiftUI

/// La acción central del producto: registrar algo en segundos.
///
/// Cada opción abre un formulario de una pantalla, pensado para completarse de
/// pie, con una mano y en una sala de espera.
struct QuickRecordSheet: View {
    let companion: Companion

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    option(
                        title: String(localized: "Medicación"),
                        detail: String(localized: "Una toma o una medicación nueva"),
                        symbol: HealthCategory.medication.symbolName
                    ) {
                        MedicationRecordView(companion: companion, onFinished: finish)
                    }

                    option(
                        title: String(localized: "Síntoma o episodio"),
                        detail: String(localized: "Algo que notaste"),
                        symbol: HealthCategory.episode.symbolName
                    ) {
                        EpisodeRecordView(companion: companion, onFinished: finish)
                    }

                    option(
                        title: String(localized: "Peso"),
                        detail: String(localized: "El peso de hoy"),
                        symbol: HealthCategory.measurement.symbolName
                    ) {
                        WeightRecordView(companion: companion, onFinished: finish)
                    }

                    option(
                        title: String(localized: "Vacuna"),
                        detail: String(localized: "Una aplicación y la próxima"),
                        symbol: HealthCategory.vaccination.symbolName
                    ) {
                        VaccinationRecordView(companion: companion, onFinished: finish)
                    }

                    option(
                        title: String(localized: "Documento"),
                        detail: String(localized: "Un estudio, una receta, un informe"),
                        symbol: HealthCategory.document.symbolName
                    ) {
                        DocumentRecordView(companion: companion, onFinished: finish)
                    }

                    option(
                        title: String(localized: "Nota"),
                        detail: String(localized: "Cualquier cosa que quieras recordar"),
                        symbol: HealthCategory.note.symbolName
                    ) {
                        NoteRecordView(companion: companion, onFinished: finish)
                    }
                } header: {
                    Text("Qué querés registrar de \(companion.displayName)")
                }
            }
            .navigationTitle(Text("Registrar"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancelar")
                    }
                }
            }
        }
    }

    private func option(
        title: String,
        detail: String,
        symbol: String,
        @ViewBuilder destination: @escaping () -> some View
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: Spacing.lg) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(Palette.accent)
                    .frame(width: Spacing.xl)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(AppFont.cardTitle)

                    Text(detail)
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)
                }
            }
            .padding(.vertical, Spacing.sm)
        }
        .accessibilityElement(children: .combine)
    }

    private func finish() {
        dismiss()
    }
}
