import Foundation
import SwiftData
import UserNotifications

/// Atiende lo que la persona hace sobre una notificación.
///
/// "Marcar como administrada" registra la toma sin abrir la app. Si ya hay otra
/// toma cercana registrada, no se guarda una segunda: el aviso con opciones no
/// existe fuera de la app, así que acá conviene no duplicar y que la persona lo
/// resuelva adentro si hace falta.
@MainActor
final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {
    var modelContainer: ModelContainer?

    /// Que el aviso se vea aunque la app esté abierta.
    ///
    /// iOS los suprime por omisión cuando la app está en primer plano, y hay que
    /// pedirle explícitamente lo contrario. Sin esto, quien estaba usando la app
    /// justo a la hora de una medicación no veía nada: el aviso llegaba y se
    /// perdía, que es exactamente lo que esta app no puede permitirse.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard
            response.actionIdentifier == ReminderScheduler.markDoseActionIdentifier,
            let rawID = response.notification.request.content.userInfo["medicationID"] as? String,
            let medicationID = UUID(uuidString: rawID),
            let modelContainer
        else {
            return
        }

        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.id == medicationID }
        )

        guard let medication = try? context.fetch(descriptor).first else { return }

        let now = Date()
        guard medication.conflictingDose(for: now) == nil else { return }

        medication.doses.append(MedicationDose(administeredAt: now))
        try? context.save()
    }

    /// Mientras la app está abierta, el aviso se muestra igual: la persona puede
    /// estar mirando otra pantalla y el recordatorio sigue siendo útil.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
