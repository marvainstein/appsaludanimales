import Foundation

enum Species: String, Codable, CaseIterable, Sendable {
    case dog
    case cat

    var label: String {
        switch self {
        case .dog: String(localized: "Perro")
        case .cat: String(localized: "Gato")
        }
    }

    var symbolName: String {
        switch self {
        case .dog: "dog"
        case .cat: "cat"
        }
    }
}

enum Sex: String, Codable, CaseIterable, Sendable {
    case female
    case male
    case unknown

    var label: String {
        switch self {
        case .female: String(localized: "Hembra")
        case .male: String(localized: "Macho")
        case .unknown: String(localized: "No se conoce")
        }
    }
}

/// Momento del día para una toma de medicación cuando no hay un horario exacto.
///
/// El horario aproximado es tan válido como el exacto: obligar a elegir una hora
/// puntual agrega fricción sin agregar precisión real.
enum TimeOfDay: String, Codable, CaseIterable, Sendable {
    case morning
    case midday
    case afternoon
    case night
    case asNeeded

    var label: String {
        switch self {
        case .morning: String(localized: "Mañana")
        case .midday: String(localized: "Mediodía")
        case .afternoon: String(localized: "Tarde")
        case .night: String(localized: "Noche")
        case .asNeeded: String(localized: "Según necesidad")
        }
    }

    var symbolName: String {
        switch self {
        case .morning: "sunrise"
        case .midday: "sun.max"
        case .afternoon: "sun.horizon"
        case .night: "moon"
        case .asNeeded: "hand.raised"
        }
    }
}
