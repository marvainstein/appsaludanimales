import Foundation
import UserNotifications

/// Programa los avisos en el sistema.
///
/// Todo es local: no hay servidor ni datos de salud saliendo del dispositivo
/// para que suene una notificación.
@MainActor
final class ReminderScheduler {
    static let shared = ReminderScheduler()

    static let markDoseActionIdentifier = "MARK_DOSE"

    private let center = UNUserNotificationCenter.current()

    private init() {}

    /// Categoría con la acción de registrar la toma desde la propia
    /// notificación: es la forma más directa de cumplir "registrar sin
    /// fricción" —sin siquiera abrir la app.
    func registerCategories() {
        let markDose = UNNotificationAction(
            identifier: Self.markDoseActionIdentifier,
            title: String(localized: "Marcar como administrada"),
            options: []
        )

        let category = UNNotificationCategory(
            identifier: ReminderCategory.medicationDose.rawValue,
            actions: [markDose],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Se pide el permiso recién cuando la persona activa un recordatorio, no al
    /// abrir la app: pedirlo antes de haber mostrado para qué sirve es la forma
    /// más rápida de que lo rechacen.
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Reemplaza todo lo programado por el plan actual. Rehacer la lista entera
    /// es más simple y más confiable que llevar la cuenta de qué cambió.
    func sync(companions: [Companion], on referenceDate: Date = .now) async {
        guard await authorizationStatus() == .authorized else { return }

        let plan = ReminderPlanBuilder.plan(for: companions, on: referenceDate)

        center.removeAllPendingNotificationRequests()

        for request in plan {
            center.add(notificationRequest(from: request))
        }
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    private func notificationRequest(from request: ReminderRequest) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default
        content.categoryIdentifier = request.category.rawValue

        if let medicationID = request.medicationID {
            content.userInfo = ["medicationID": medicationID.uuidString]
        }

        return UNNotificationRequest(
            identifier: request.id,
            content: content,
            trigger: trigger(from: request.trigger)
        )
    }

    private func trigger(from trigger: ReminderRequest.Trigger) -> UNNotificationTrigger {
        switch trigger {
        case let .daily(hour, minute):
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        case let .at(date):
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
    }
}
