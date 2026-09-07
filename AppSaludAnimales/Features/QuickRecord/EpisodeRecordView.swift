import SwiftData
import SwiftUI

/// Registrar un síntoma o episodio.
///
/// Alcanza con el síntoma: la descripción, la intensidad y la hora exacta se
/// pueden dejar como están. Registrar rápido es más importante que registrar
/// completo, porque lo incompleto se puede editar y lo no registrado se pierde.
struct EpisodeRecordView: View {
    let companion: Companion
    var onFinished: () -> Void = {}

    @Environment(\.modelContext) private var modelContext

    @State private var symptom = ""
    @State private var episodeDescription = ""
    @State private var date = Date()
    @State private var intensity: EpisodeIntensity?
    @State private var saveErrorMessage: String?

    private var canSave: Bool {
        !symptom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var suggestions: [String] {
        SymptomSuggestions.matching(symptom)
    }

    var body: some View {
        Form {
            Section {
                LabeledTextField(
                    label: String(localized: "Qué notaste"),
                    text: $symptom,
                    isRequired: true
                )

                if !suggestions.isEmpty {
                    suggestionList
                }
            } header: {
                Text("Síntoma")
            }

            Section {
                DatePicker(selection: $date, in: ...Date()) {
                    Text("Cuándo")
                }

                Picker(selection: $intensity) {
                    Text("Sin especificar").tag(EpisodeIntensity?.none)
                    ForEach(EpisodeIntensity.allCases, id: \.self) { level in
                        Text(level.label).tag(EpisodeIntensity?.some(level))
                    }
                } label: {
                    Text("Intensidad")
                }

                LabeledTextField(
                    label: String(localized: "Descripción"),
                    text: $episodeDescription,
                    hint: String(localized: "Con tus palabras, como se lo contarías al veterinario.")
                )
            } header: {
                Text("Detalles")
            } footer: {
                Text("Se guarda como episodio activo. Podés marcarlo en seguimiento o resuelto más adelante.")
            }

            PrimaryButtonSection(
                title: String(localized: "Guardar el episodio"),
                hint: canSave ? nil : String(localized: "Escribí qué notaste para poder guardarlo"),
                isEnabled: canSave,
                action: save
            )
        }
        .navigationTitle(Text("Episodio"))
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

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Sugerencias")
                .font(AppFont.caption)
                .foregroundStyle(Palette.inkMuted)
                .accessibilityAddTraits(.isHeader)

            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    symptom = suggestion
                } label: {
                    HStack {
                        Text(suggestion)
                            .font(AppFont.body)
                            .foregroundStyle(Palette.ink)

                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
                .accessibilityHint(Text("Usa esta sugerencia como síntoma"))
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private func save() {
        let episode = HealthEpisode(
            symptom: symptom.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            episodeDescription: episodeDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : episodeDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            status: .active
        )
        episode.intensity = intensity
        companion.episodes.append(episode)

        do {
            try modelContext.save()
            onFinished()
        } catch {
            saveErrorMessage = String(localized: "El episodio no se guardó. Podés intentar de nuevo en un momento.")
        }
    }
}
