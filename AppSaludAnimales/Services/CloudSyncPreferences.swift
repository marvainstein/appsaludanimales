import Foundation

/// Qué decidió la persona sobre guardar una copia en su iCloud.
///
/// Se pregunta una sola vez y no se insiste. Pero "una sola vez" significa que
/// la app no vuelve a molestar, no que la decisión sea para siempre: quien tocó
/// "ahora no" —o lo tocó por error— la encuentra en Respaldo cuando quiera.
///
/// La perilla va en un solo sentido a propósito. Pasar de local a sincronizado
/// es sencillo: los datos ya están en el teléfono y empiezan a subirse. El
/// camino de vuelta es el complicado, porque hay que decidir qué pasa con la
/// copia que ya está en iCloud, y no es una pregunta que corresponda hacerle a
/// alguien desde un interruptor.
enum CloudSyncPreferences {
    private static let enabledKey = "sync.enabled"
    private static let decidedKey = "sync.decidedAt"

    /// Si la persona activó la copia automática.
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledKey)
            decidedAt = Date()
        }
    }

    /// Cuándo contestó, sea que sí o que no. Sirve para no volver a ofrecerlo.
    static var decidedAt: Date? {
        get {
            let stored = UserDefaults.standard.double(forKey: decidedKey)
            return stored > 0 ? Date(timeIntervalSince1970: stored) : nil
        }
        set {
            guard let newValue else {
                UserDefaults.standard.removeObject(forKey: decidedKey)
                return
            }
            UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: decidedKey)
        }
    }

    /// Registra un "ahora no" sin activar nada.
    static func declineForNow() {
        UserDefaults.standard.set(false, forKey: enabledKey)
        decidedAt = Date()
    }
}
