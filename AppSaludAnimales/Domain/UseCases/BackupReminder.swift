import Foundation

/// Cuándo conviene ofrecer un respaldo.
///
/// Un respaldo que hay que acordarse de hacer es un respaldo débil: el día que
/// se pierde el teléfono, el último es de hace ocho meses. Así que la app
/// pregunta.
///
/// Pregunta, no reta. Nada de "¡tus datos están en riesgo!" ni de contadores de
/// días sin respaldar. Se ofrece como una pregunta abierta, se puede decir que
/// no, y decir que no dura meses y no hasta mañana.
enum BackupReminder {
    /// Tres meses. Suficiente para que perder lo del medio duela poco, y lo
    /// bastante espaciado como para no volverse ruido.
    static let interval: TimeInterval = 90 * 24 * 60 * 60

    /// Cuando se dice "ahora no", la pregunta se va por un mes entero.
    static let snooze: TimeInterval = 30 * 24 * 60 * 60

    /// Antes de las dos semanas de uso no se pregunta nada: alguien que recién
    /// empieza no tiene todavía nada que perder, y arrancar pidiendo cosas es
    /// la mejor forma de que abandone.
    static let gracePeriod: TimeInterval = 14 * 24 * 60 * 60

    static func shouldOffer(
        lastBackup: Date?,
        snoozedAt: Date?,
        oldestRecord: Date?,
        now: Date = .now
    ) -> Bool {
        guard let oldestRecord, now.timeIntervalSince(oldestRecord) >= gracePeriod else {
            return false
        }

        if let snoozedAt, now.timeIntervalSince(snoozedAt) < snooze {
            return false
        }

        guard let lastBackup else { return true }

        return now.timeIntervalSince(lastBackup) >= interval
    }

    static func message(lastBackup: Date?, now: Date = .now) -> String {
        guard let lastBackup else {
            return String(localized: "Todavía no hiciste ningún respaldo. Si el teléfono se pierde o se rompe, la historia de salud se pierde con él.")
        }

        let months = max(1, Int(now.timeIntervalSince(lastBackup) / (30 * 24 * 60 * 60)))

        return months == 1
            ? String(localized: "El último respaldo es de hace un mes.")
            : String(localized: "El último respaldo es de hace \(months) meses.")
    }
}
