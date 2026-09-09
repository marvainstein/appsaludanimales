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
    /// Rearma todos los avisos.
    ///
    /// `askingIfNeeded` solo va en verdadero cuando alguien acaba de guardar
    /// algo con aviso: ahí ya dijo que quiere que le avisen, y es el mejor
    /// momento para pedir el permiso. Al volver a la app va en falso, porque
    /// pedir permiso apenas se abre, sin haber mostrado para qué sirve, es la
    /// forma más rápida de que lo rechacen.
    func sync(
        companions: [Companion],
        on referenceDate: Date = .now,
        askingIfNeeded: Bool = false
    ) async {
        if askingIfNeeded, await authorizationStatus() == .notDetermined {
            _ = await requestAuthorization()
        }

        guard await authorizationStatus() == .authorized else { return }

        // A quien ya no está no se le piden medicaciones. Un aviso así, meses
        // después, es lo peor que podría hacer esta app.
        let plan = ReminderPlanBuilder.plan(
            for: companions.filter(\.isPresent),
            on: referenceDate
        )

        center.removeAllPendingNotificationRequests()

        for request in plan {
            // Si el sistema rechaza un aviso puntual, los demás se programan
            // igual: perder un recordatorio es mejor que perderlos todos.
            try? await center.add(notificationRequest(from: request))
        }
    }

    /// Lo que está efectivamente programado en el sistema, para poder mirarlo.
    ///
    /// Existe porque un aviso que no llega no deja rastro: no se puede saber si
    /// nunca se programó, si se programó mal o si el sistema lo descartó. Con
    /// esto se puede abrir Recordatorios y ver la lista de verdad, en vez de
    /// adivinar.
    func scheduled() async -> [ScheduledReminder] {
        let pending = await center.pendingNotificationRequests()

        return pending
            .map { request in
                ScheduledReminder(
                    id: request.identifier,
                    title: request.content.title,
                    body: request.content.body,
                    nextDate: (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
                )
            }
            .sorted { ($0.nextDate ?? .distantFuture) < ($1.nextDate ?? .distantFuture) }
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
