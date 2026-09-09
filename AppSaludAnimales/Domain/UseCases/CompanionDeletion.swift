import Foundation

/// Lo que se dice antes de eliminar a un compañero.
///
/// Eliminar y "cruzó el arcoíris" son dos cosas distintas y es fácil confundirlas
/// en el peor momento. Eliminar es para el que se cargó por error o el que ya no
/// se cuida —alguien que se mudó, un animal que se dio en adopción—: borra todo y
/// no se puede deshacer.
///
/// Por eso el aviso dice cuántos registros se van con él. Un número concreto
/// frena mejor que cualquier advertencia genérica: "se van a borrar 214
/// registros" se entiende de otra manera que "esta acción es irreversible".
enum CompanionDeletion {
    static func warningMessage(name: String, recordCount: Int) -> String {
        guard recordCount > 0 else {
            return String(localized: "Se elimina \(name) de la app. No se puede deshacer.")
        }

        return recordCount == 1
            ? String(localized: "Se eliminan \(name) y el registro que tiene cargado. No se puede deshacer.")
            : String(localized: "Se eliminan \(name) y los \(recordCount) registros que tiene cargados. No se puede deshacer.")
    }
}
