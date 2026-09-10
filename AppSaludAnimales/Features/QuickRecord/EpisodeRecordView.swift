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

    /// Con un episodio ya guardado, la misma pantalla lo edita. El estado
    /// —activo, en seguimiento, resuelto— no se toca acá: se cambia desde el
    /// detalle, que es donde se lo mira.
    private let editing: HealthEpisode?

    @Environment(\.modelContext) private var modelContext

    @State private var symptom: String
    @State private var episodeDescription: String
    @State private var date: Date
    @State private var intensity: EpisodeIntensity?
    @State private var status: EpisodeStatus
    @State private var saveErrorMessage: String?

    init(
        companion: Companion,
        editing: HealthEpisode? = nil,
        onFinished: @escaping () -> Void = {}
    ) {
        self.companion = companion
        self.editing = editing
        self.onFinished = onFinished
        _symptom = State(initialValue: editing?.symptom ?? "")
        _episodeDescription = State(initialValue: editing?.episodeDescription ?? "")
        _date = State(initialValue: editing?.date ?? Date())
        _intensity = State(initialValue: editing?.intensity)
        _status = State(initialValue: editing?.status ?? .active)
    }

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
                    .foregroundStyle(Palette.inkMuted)
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

                // Muchas veces se anota algo que ya pasó: una convulsión de
                // anteayer, una cojera que se fue sola. Dar por sentado que
                // sigue abierto obligaba a guardarlo mal y corregirlo después.
                Picker(selection: $status) {
                    ForEach(EpisodeStatus.allCases, id: \.self) { option in
                        Text(option.label).tag(option)
                    }
                } label: {
                    Text("Cómo está")
                }

                LabeledTextField(
                    label: String(localized: "Descripción"),
                    text: $episodeDescription,
                    hint: String(localized: "Con tus palabras, como se lo contarías al veterinario.")
                )
            } header: {
                Text("Detalles")
                    .foregroundStyle(Palette.inkMuted)
            } footer: {
                Text("Se puede cambiar más adelante, desde el detalle del episodio.")
                    .foregroundStyle(Palette.inkMuted)
            }

            PrimaryButtonSection(
                title: editing == nil
                    ? String(localized: "Guardar el episodio")
                    : String(localized: "Guardar los cambios"),
                hint: canSave ? nil : String(localized: "Escribí qué notaste para poder guardarlo"),
                isEnabled: canSave,
                action: save
            )
        }
        .navigationTitle(Text(editing == nil
            ? String(localized: "Episodio")
            : String(localized: "Editar el episodio")))
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
        let trimmedDescription = episodeDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let episode = editing ?? HealthEpisode(date: date)

        episode.symptom = symptom.trimmingCharacters(in: .whitespacesAndNewlines)
        episode.date = date
        episode.episodeDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
        episode.intensity = intensity
        episode.status = status

        // Un episodio que se anota ya resuelto se resolvió cuando pasó, no hoy.
        if status == .resolved, episode.resolvedAt == nil {
            episode.resolvedAt = date
        } else if status != .resolved {
            episode.resolvedAt = nil
        }

        if editing == nil {
            companion.episodes.append(episode)
        }

        do {
            try modelContext.save()
            onFinished()
        } catch {
            saveErrorMessage = String(localized: "El episodio no se guardó. Podés intentar de nuevo en un momento.")
        }
    }
}
