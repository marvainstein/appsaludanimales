import Foundation
import SwiftData

/// Profesional: veterinaria de cabecera, fisioterapeuta, especialista.
///
/// Un solo tipo con un rol, en vez de entidades separadas por especialidad: la
/// diferencia entre "veterinario de cabecera" y "otro profesional" es un rol,
/// no una estructura distinta.
@Model
final class Professional {
    var id: UUID = UUID()
    var name: String = ""
    var role: String?
    var clinic: String?
    var phone: String?
    var email: String?
    var notes: String?

    /// Profesional de referencia que se muestra en el modo emergencia.
    var isPrimaryVeterinarian: Bool = false
    var createdAt: Date = Date()

    var companions: [Companion] = []

    init(name: String = "", role: String? = nil, phone: String? = nil, isPrimaryVeterinarian: Bool = false) {
        self.name = name
        self.role = role
        self.phone = phone
        self.isPrimaryVeterinarian = isPrimaryVeterinarian
    }
}

/// Persona responsable de un compañero. Varias personas pueden compartir el
/// cuidado; en el MVP se registran localmente y en V1 se conectan con la
/// sincronización compartida de iCloud.
@Model
final class ResponsiblePerson {
    var id: UUID = UUID()
    var name: String = ""
    var phone: String?
    var email: String?
    var isPrimary: Bool = false
    var createdAt: Date = Date()

    var companions: [Companion] = []

    init(name: String = "", phone: String? = nil, isPrimary: Bool = false) {
        self.name = name
        self.phone = phone
        self.isPrimary = isPrimary
    }
}
