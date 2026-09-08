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
                        symbol: HealthCategory.medication.symbolName,
                        identifier: "quickRecord.medication"
                    ) {
                        MedicationRecordView(companion: companion, onFinished: finish)
                    }

                    option(
                        title: String(localized: "Síntoma o episodio"),
                        detail: String(localized: "Algo que notaste"),
                        symbol: HealthCategory.episode.symbolName,
                        identifier: "quickRecord.episode"
                    ) {
                        EpisodeRecordView(companion: companion, onFinished: finish)
                    }

                    option(
                        title: String(localized: "Peso"),
                        detail: String(localized: "El peso de hoy"),
                        symbol: HealthCategory.measurement.symbolName,
                        identifier: "quickRecord.weight"
                    ) {
                        WeightRecordView(companion: companion, onFinished: finish)
                    }

                    option(
                        title: String(localized: "Vacuna"),
                        detail: String(localized: "Una aplicación y la próxima"),
                        symbol: HealthCategory.vaccination.symbolName,
                        identifier: "quickRecord.vaccination"
                    ) {
                        VaccinationRecordView(companion: companion, onFinished: finish)
                    }

                    option(
                        title: String(localized: "Documento"),
                        detail: String(localized: "Un estudio, una receta, un informe"),
                        symbol: HealthCategory.document.symbolName,
                        identifier: "quickRecord.document"
                    ) {
                        DocumentRecordView(companion: companion, onFinished: finish)
                    }

                    option(
                        title: String(localized: "Nota"),
                        detail: String(localized: "Cualquier cosa que quieras recordar"),
                        symbol: HealthCategory.note.symbolName,
                        identifier: "quickRecord.note"
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
        identifier: String,
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
        // Dentro de una lista, `.combine` no llega a unir el título con su
        // detalle: la auditoría los encuentra como dos elementos sueltos, y con
        // VoiceOver eso son doce paradas en vez de seis. Con la etiqueta y la
        // pista escritas a mano, cada fila es una sola cosa: se anuncia "Peso" y
        // el detalle queda como pista, que es donde corresponde.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(detail))
        // Al reemplazar el elemento por uno propio se pierde el rasgo de botón
        // que el enlace traía solo, y sin él VoiceOver anuncia "Peso" sin decir
        // que se puede tocar.
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(identifier)
    }

    private func finish() {
        dismiss()
    }
}
