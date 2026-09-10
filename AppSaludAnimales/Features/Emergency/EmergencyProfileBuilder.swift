import Foundation

struct EmergencyContact: Equatable {
    var name: String
    var role: String?
    var phone: String?

    /// Solo la veterinaria que la persona marcó como de cabecera. Sin esto, la
    /// pantalla llamaría "de cabecera" a la primera de la lista aunque nadie la
    /// haya marcado, que es afirmar algo que no sabemos.
    var isPrimary: Bool = false

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
    /// Las veterinarias guardadas, con la de cabecera primero.
    ///
    /// Son varias a propósito: la de siempre puede no atender a las tres de la
    /// mañana, y la que atiende de urgencia puede no ser la que conoce la
    /// historia.
    var veterinarians: [EmergencyContact]

    /// Puede haber más de una persona a cargo. Aparecen en orden: primero la
    /// principal, después las demás.
    var responsiblePeople: [EmergencyContact]

    /// Lo que falta cargar, para poder ofrecerlo con amabilidad en vez de
    /// mostrar huecos sin explicación.
    var missingEssentials: [String] {
        var missing: [String] = []

        if !veterinarians.contains(where: { $0.callURL != nil }) {
            missing.append(String(localized: "el teléfono de una veterinaria"))
        }

        if !responsiblePeople.contains(where: { $0.callURL != nil }) {
            missing.append(String(localized: "el teléfono de una persona a cargo"))
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
            veterinarians: veterinarians(for: companion),
            responsiblePeople: companion.orderedResponsiblePeople.map { person in
                EmergencyContact(
                    name: person.name,
                    role: person.isPrimary && companion.responsiblePeople.count > 1
                        ? String(localized: "Contacto principal")
                        : nil,
                    phone: nonEmpty(person.phone)
                )
            }
        )
    }

    private static func describe(_ medication: Medication) -> String {
        guard let dose = nonEmpty(medication.dose) else { return medication.name }
        return "\(medication.name) · \(dose)"
    }

    /// Todas las veterinarias cargadas, con la de cabecera primero y el resto en
    /// el orden en que se cargaron.
    private static func veterinarians(for companion: Companion) -> [EmergencyContact] {
        companion.professionals
            .sorted { lhs, rhs in
                lhs.isPrimaryVeterinarian == rhs.isPrimaryVeterinarian
                    ? lhs.createdAt < rhs.createdAt
                    : lhs.isPrimaryVeterinarian
            }
            .map { professional in
                EmergencyContact(
                    name: professional.name,
                    role: nonEmpty(professional.clinic) ?? nonEmpty(professional.role),
                    phone: nonEmpty(professional.phone),
                    isPrimary: professional.isPrimaryVeterinarian
                )
            }
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
