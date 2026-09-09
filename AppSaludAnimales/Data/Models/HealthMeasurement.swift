import Foundation
import SwiftData

/// Medición de un valor a lo largo del tiempo. Hoy solo peso; el tipo está en el
/// modelo para no tener que migrar cuando se agregue otra medición.
@Model
final class HealthMeasurement {
    var id: UUID = UUID()
    var kindRawValue: String = HealthMeasurementKind.weight.rawValue
    var value: Double = 0
    var unit: String = "kg"
    var date: Date = Date()
    var notes: String?
    var createdAt: Date = Date()

    var companion: Companion?

    init(kind: HealthMeasurementKind = .weight, value: Double = 0, unit: String = "kg", date: Date = Date()) {
        self.kindRawValue = kind.rawValue
        self.value = value
        self.unit = unit
        self.date = date
    }
}

enum HealthMeasurementKind: String, Codable, CaseIterable, Sendable {
    case weight

    var label: String {
        switch self {
        case .weight: String(localized: "Peso")
        }
    }
}

extension HealthMeasurement {
    var kind: HealthMeasurementKind {
        get { HealthMeasurementKind(rawValue: kindRawValue) ?? .weight }
        set { kindRawValue = newValue.rawValue }
    }

    var formattedValue: String {
        let number = value.formatted(.number.precision(.fractionLength(0...2)))
        return "\(number) \(unit)"
    }
}

extension HealthMeasurement: HealthTimelineItem {
    var timelineRecordedAt: Date { createdAt }
    var timelineDate: Date { date }
    var timelineTitle: String { formattedValue }
    var timelineCategory: HealthCategory { .measurement }
}
