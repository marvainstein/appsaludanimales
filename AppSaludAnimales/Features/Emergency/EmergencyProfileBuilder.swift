import Foundation

struct EmergencyContact: Equatable {
    var name: String
    var role: String?
    var phone: String?

    var callURL: URL? {
        PhoneNumberLink.callURL(for: phone)
    }
}

/// Lo que hace falta saber cuando no hay tiempo de buscar nada.
///
/// El orden de los campos es el orden de urgencia, no el orden en que se
/// cargaron: primero quién es, después lo que puede cambiar una decisión
/// clínica, y al final a quién llamar.
struct EmergencyProfile: Equatable {
    var displayName: String
    var speciesLabel: String
    var ageText: String?
    var allergies: String?
    var conditions: String?
    var medications: [String]
    var treatments: [String]
    var veterinarian: EmergencyContact?
    var responsiblePerson: EmergencyContact?

    /// Lo que falta cargar, para poder ofrecerlo con amabilidad en vez de
    /// mostrar huecos sin explicación.
    var missingEssentials: [String] {
        var missing: [String] = []

        if veterinarian?.callURL == nil {
            missing.append(String(localized: "el teléfono del veterinario"))
        }

        if responsiblePerson?.callURL == nil {
            missing.append(String(localized: "el teléfono de la persona responsable"))
        }

        return missing
    }
}

enum EmergencyProfileBuilder {
    static func profile(
        for companion: Companion,
        on referenceDate: Date = .now
    ) -> EmergencyProfile {
        EmergencyProfile(
            displayName: companion.displayName,
            speciesLabel: companion.species.label,
            ageText: companion.age?.formatted,
            allergies: nonEmpty(companion.allergies),
            conditions: nonEmpty(companion.relevantConditions),
            medications: companion.activeMedications(on: referenceDate)
                .sorted { $0.name < $1.name }
                .map(describe),
            treatments: companion.activeTreatments(on: referenceDate)
                .sorted { $0.name < $1.name }
                .map(\.name),
            veterinarian: veterinarian(for: companion),
            responsiblePerson: responsiblePerson(for: companion)
        )
    }

    private static func describe(_ medication: Medication) -> String {
        guard let dose = nonEmpty(medication.dose) else { return medication.name }
        return "\(medication.name) · \(dose)"
    }

    /// El veterinario de cabecera si está marcado; si no, el primer profesional
    /// cargado, que en una emergencia es mejor que nada.
    private static func veterinarian(for companion: Companion) -> EmergencyContact? {
        let professional = companion.professionals.first(where: \.isPrimaryVeterinarian)
            ?? companion.professionals.first

        guard let professional else { return nil }

        return EmergencyContact(
            name: professional.name,
            role: nonEmpty(professional.clinic) ?? nonEmpty(professional.role),
            phone: nonEmpty(professional.phone)
        )
    }

    private static func responsiblePerson(for companion: Companion) -> EmergencyContact? {
        let person = companion.responsiblePeople.first(where: \.isPrimary)
            ?? companion.responsiblePeople.first

        guard let person else { return nil }

        return EmergencyContact(
            name: person.name,
            role: nil,
            phone: nonEmpty(person.phone)
        )
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
