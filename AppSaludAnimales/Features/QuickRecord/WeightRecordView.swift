import SwiftData
import SwiftUI

/// Registrar el peso: un número y listo.
struct WeightRecordView: View {
    let companion: Companion
    var onFinished: () -> Void = {}

    @Environment(\.modelContext) private var modelContext

    @State private var weightText = ""
    @State private var date = Date()
    @State private var saveErrorMessage: String?

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
            } footer: {
                if let previous = previousWeightSummary {
                    Text(previous)
                }
            }

            PrimaryButtonSection(
                title: String(localized: "Guardar el peso"),
                hint: parsedWeight == nil
                    ? String(localized: "Escribí el peso para poder guardarlo")
                    : nil,
                isEnabled: parsedWeight != nil,
                action: save
            )
        }
        .navigationTitle(Text("Peso"))
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
        guard let latest = companion.latestWeight else { return nil }

        return String(localized: "Último peso registrado: \(latest.formattedValue), \(DateDescription.relative(latest.date).lowercased()).")
    }

    private func save() {
        guard let value = parsedWeight else { return }

        let measurement = HealthMeasurement(kind: .weight, value: value, unit: "kg", date: date)
        companion.measurements.append(measurement)

        do {
            try modelContext.save()
            onFinished()
        } catch {
            saveErrorMessage = String(localized: "El peso no se guardó. Podés intentar de nuevo en un momento.")
        }
    }
}
