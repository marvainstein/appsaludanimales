import Foundation

/// Cuándo fue el último respaldo, y cuándo se dijo "ahora no".
///
/// Vive en los ajustes del sistema y no en la base de datos: son dos fechas de
/// este teléfono, no información de salud. No viajan en el respaldo, que sería
/// además un poco absurdo.
enum BackupPreferences {
    private static let lastBackupKey = "backup.lastDate"
    private static let snoozedKey = "backup.snoozedAt"

    static var lastBackup: Date? {
        get { date(for: lastBackupKey) }
        set { store(newValue, for: lastBackupKey) }
    }

    static var snoozedAt: Date? {
        get { date(for: snoozedKey) }
        set { store(newValue, for: snoozedKey) }
    }

    private static func date(for key: String) -> Date? {
        let stored = UserDefaults.standard.double(forKey: key)
        return stored > 0 ? Date(timeIntervalSince1970: stored) : nil
    }

    private static func store(_ date: Date?, for key: String) {
        guard let date else {
            UserDefaults.standard.removeObject(forKey: key)
            return
        }

        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: key)
    }
}
