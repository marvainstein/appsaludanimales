import Foundation

/// Categorías de la línea de tiempo de salud.
///
/// Se guarda como texto en las entidades para poder incorporar categorías nuevas
/// sin migrar el esquema; este enum representa las conocidas por la app.
enum HealthCategory: String, Codable, CaseIterable, Sendable {
    case consultation
    case vaccination
    case medication
    case treatment
    case preventive
    case study
    case episode
    case surgery
    case measurement
    case appointment
    case document
    case note

    var label: String {
        switch self {
        case .consultation: String(localized: "Consulta")
        case .vaccination: String(localized: "Vacuna")
        case .medication: String(localized: "Medicación")
        case .treatment: String(localized: "Tratamiento")
        case .preventive: String(localized: "Prevención")
        case .study: String(localized: "Estudio")
        case .episode: String(localized: "Episodio")
        case .surgery: String(localized: "Cirugía")
        case .measurement: String(localized: "Peso")
        case .appointment: String(localized: "Turno")
        case .document: String(localized: "Documento")
        case .note: String(localized: "Nota")
        }
    }

    var symbolName: String {
        switch self {
        case .consultation: "stethoscope"
        case .vaccination: "syringe"
        case .medication: "pills"
        case .treatment: "heart.text.square"
        case .preventive: "shield"
        case .study: "waveform.path.ecg"
        case .episode: "exclamationmark.bubble"
        case .surgery: "cross.case"
        case .measurement: "scalemass"
        case .appointment: "calendar"
        case .document: "doc.text"
        case .note: "note.text"
        }
    }
}

/// Forma común de todo lo que aparece en la línea de tiempo y en el resumen para
/// el veterinario. Permite recorrer entidades distintas sin repetir código en el
/// historial, el dashboard y el PDF.
protocol HealthTimelineItem {
    var timelineDate: Date { get }
    var timelineTitle: String { get }
    var timelineCategory: HealthCategory { get }
    var timelineStatus: (any StatusPresentable)? { get }
}

extension HealthTimelineItem {
    var timelineStatus: (any StatusPresentable)? { nil }
}
