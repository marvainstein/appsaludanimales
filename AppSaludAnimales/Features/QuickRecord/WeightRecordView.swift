import SwiftData
import SwiftUI

/// Registrar el peso: un número y listo.
struct WeightRecordView: View {
    let companion: Companion
    var onFinished: () -> Void = {}

    /// Cuando llega un peso ya guardado, la misma pantalla lo edita en lugar de
    /// crear uno nuevo. Corregir un número mal tipeado tiene que costar lo mismo
    /// que escribirlo.
    private let editing: HealthMeasurement?

    @Environment(\.modelContext) private var modelContext

    @State private var weightText: String
    @State private var date: Date
    @State private var saveErrorMessage: String?

    init(
        companion: Companion,
        editing: HealthMeasurement? = nil,
        onFinished: @escaping () -> Void = {}
    ) {
        self.companion = companion
        self.editing = editing
        self.onFinished = onFinished
        _weightText = State(initialValue: editing.map { $0.value.formatted() } ?? "")
        _date = State(initialValue: editing?.date ?? Date())
    }

    private var parsedWeight: Double? {
        WeightInputParser.parse(weightText)
    }

    var body: some View {
        Form {
            Section {
                LabeledTextField(
                    label: String(localized: "Peso en kilogramos"),
                    text: $weightText,
                    hint: WeightInputParser.guidance(for: weightText),
                    isRequired: true,
                    keyboardType: .decimalPad
                )

                DatePicker(selection: $date, in: ...Date(), displayedComponents: [.date]) {
                    Text("Fecha")
                }
            } header: {
                Text("Peso")
                    .foregroundStyle(Palette.inkMuted)
            } footer: {
                if let previous = previousWeightSummary {
                    Text(previous)
                        .foregroundStyle(Palette.inkMuted)
                }
            }

            PrimaryButtonSection(
                title: editing == nil
                    ? String(localized: "Guardar el peso")
                    : String(localized: "Guardar los cambios"),
                hint: parsedWeight == nil
                    ? String(localized: "Escribí el peso para poder guardarlo")
                    : nil,
                isEnabled: parsedWeight != nil,
                action: save
            )
        }
        .navigationTitle(Text(editing == nil
            ? String(localized: "Peso")
            : String(localized: "Editar el peso")))
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

    /// Contexto útil sin pedir nada: cuánto pesaba la última vez y cuándo.
    private var previousWeightSummary: String? {
        // Editando, el "último peso" suele ser este mismo registro: mostrarlo
        // como referencia confunde en vez de ayudar.
        guard editing == nil, let latest = companion.latestWeight else { return nil }

        return String(localized: "Último peso registrado: \(latest.formattedValue), \(DateDescription.relative(latest.date).lowercased()).")
    }

    private func save() {
        guard let value = parsedWeight else { return }

        if let editing {
            editing.value = value
            editing.date = date
        } else {
            let measurement = HealthMeasurement(kind: .weight, value: value, unit: "kg", date: date)
            companion.measurements.append(measurement)
        }

        do {
            try modelContext.save()
            onFinished()
        } catch {
            saveErrorMessage = String(localized: "El peso no se guardó. Podés intentar de nuevo en un momento.")
        }
    }
}
