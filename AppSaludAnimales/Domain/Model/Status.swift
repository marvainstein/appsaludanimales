import Foundation

/// Intención semántica de un estado. Es independiente del color de acento del
/// producto: el color es el complemento, nunca el portador de la información.
enum StatusTone: String, Sendable, CaseIterable {
    case neutral
    case positive
    case attention
    case critical
}

/// Todo estado del producto expone texto e ícono además de tono, para cumplir la
/// regla de no comunicar información únicamente con color.
protocol StatusPresentable {
    var label: String { get }
    var symbolName: String { get }
    var tone: StatusTone { get }
}

/// Estado de una medicación, tratamiento o tratamiento preventivo.
enum ActivityStatus: String, Codable, CaseIterable, Sendable, StatusPresentable {
    case active
    case finished
    case suspended

    var label: String {
        switch self {
        case .active: String(localized: "Activo")
        case .finished: String(localized: "Finalizado")
        case .suspended: String(localized: "Suspendido")
        }
    }

    var symbolName: String {
        switch self {
        case .active: "circle.inset.filled"
        case .finished: "checkmark.circle"
        case .suspended: "pause.circle"
        }
    }

    var tone: StatusTone {
        switch self {
        case .active: .positive
        case .finished: .neutral
        case .suspended: .attention
        }
    }
}

/// Estado de un episodio de salud.
enum EpisodeStatus: String, Codable, CaseIterable, Sendable, StatusPresentable {
    case active
    case monitoring
    case resolved

    var label: String {
        switch self {
        case .active: String(localized: "Activo")
        case .monitoring: String(localized: "En seguimiento")
        case .resolved: String(localized: "Resuelto")
        }
    }

    var symbolName: String {
        switch self {
        case .active: "exclamationmark.circle"
        case .monitoring: "eye.circle"
        case .resolved: "checkmark.circle"
        }
    }

    var tone: StatusTone {
        switch self {
        case .active: .critical
        case .monitoring: .attention
        case .resolved: .positive
        }
    }
}

enum MedicationStatusResolver {
    static func status(
        startDate: Date?,
        endDate: Date?,
        isSuspended: Bool,
        on referenceDate: Date = .now
    ) -> ActivityStatus {
        if isSuspended { return .suspended }
        if let endDate, endDate < referenceDate { return .finished }
        return .active
    }
}
