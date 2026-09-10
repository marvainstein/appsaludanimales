import Foundation

/// Si la copia automática se puede usar en este teléfono, y si no, por qué.
///
/// El motivo importa tanto como el resultado. Los dos casos que fallan —iCloud
/// apagado y espacio agotado— fallan callados si uno no los mira: la persona
/// toca "activar", no pasa nada visible, y queda creyendo que su información
/// está a salvo. En una app hecha para que no se pierda una historia clínica,
/// eso es lo único inaceptable.
enum CloudSyncAvailability: Equatable {
    /// Se puede activar.
    case disponible

    /// La persona tiene iCloud apagado en este teléfono.
    case iCloudApagado

    /// No entra: la cuenta de iCloud no tiene espacio libre.
    case sinEspacio

    /// La app todavía no tiene habilitado iCloud. Es el estado mientras no
    /// exista la cuenta de desarrollador paga, que es lo único que habilita la
    /// capacidad de iCloud en el proyecto.
    case noHabilitada

    /// Qué se le dice a la persona, sin echarle la culpa de nada.
    var titulo: String? {
        switch self {
        case .disponible:
            nil
        case .iCloudApagado:
            String(localized: "Para esto hace falta iCloud")
        case .sinEspacio:
            String(localized: "No hay lugar en tu iCloud")
        case .noHabilitada:
            String(localized: "Todavía no está disponible")
        }
    }

    var explicacion: String? {
        switch self {
        case .disponible:
            nil
        case .iCloudApagado:
            String(localized: "En este teléfono está apagado. Se activa desde Ajustes: tocá tu nombre arriba de todo, después iCloud, y ahí prendé Estela.")
        case .sinEspacio:
            String(localized: "Tu cuenta de iCloud no tiene espacio libre. Se puede liberar desde Ajustes, o guardar el respaldo como archivo, que no ocupa nada de tu iCloud.")
        case .noHabilitada:
            String(localized: "Esta versión de la app todavía no puede guardar la copia sola. El respaldo como archivo funciona igual.")
        }
    }

    /// Ninguno de estos avisos es un callejón sin salida, y por eso no hace
    /// falta un botón que lleve a otro lado: el aviso aparece parado sobre la
    /// pantalla de Respaldo, con el archivo a un dedo de distancia. Para quien
    /// decidió no usar iCloud, ese archivo no es un premio consuelo: es la
    /// respuesta correcta.

    static func current() -> CloudSyncAvailability {
        // Sin la capacidad de iCloud habilitada en el proyecto no hay nada que
        // consultar: el contenedor todavía se arma con `cloudKitDatabase: .none`.
        // Cuando exista la cuenta paga, acá se mira la cuenta de verdad.
        guard AppCapabilities.cloudSyncIsBuilt else { return .noHabilitada }

        guard FileManager.default.ubiquityIdentityToken != nil else {
            return .iCloudApagado
        }

        return .disponible
    }
}

/// Lo que esta compilación de la app sabe hacer.
///
/// Existe para que la pantalla se pueda construir y probar antes de tener la
/// cuenta de desarrollador: hoy la app muestra el camino de error, que es
/// justamente el que más importa que quede bien y el más difícil de provocar
/// una vez que todo funciona.
enum AppCapabilities {
    static let cloudSyncIsBuilt = false
}
