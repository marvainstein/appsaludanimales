import SwiftData
import SwiftUI
import UserNotifications

@main
struct AppSaludAnimalesApp: App {
    private let container: ModelContainer
    private let notificationHandler = NotificationActionHandler()

    /// Cuando el almacenamiento permanente falla, la app sigue abriendo con un
    /// almacenamiento temporal y lo dice con claridad, en vez de cerrarse.
    private let storageIsTemporary: Bool

    @Environment(\.scenePhase) private var scenePhase

    /// Las pruebas de interfaz arrancan siempre desde cero: si arrastraran lo
    /// registrado en la corrida anterior, el recorrido cambiaría de una vez a
    /// otra y las fallas dejarían de significar algo.
    private static var isRunningUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiTesting")
    }

    init() {
        if Self.isRunningUITests,
           let container = try? ModelContainerFactory.makeContainer(inMemory: true) {
            self.container = container
            self.storageIsTemporary = false
        } else if let container = try? ModelContainerFactory.makeContainer() {
            self.container = container
            self.storageIsTemporary = false
        } else {
            self.container = try! ModelContainerFactory.makeContainer(inMemory: true)
            self.storageIsTemporary = true
        }

        notificationHandler.modelContainer = container
        UNUserNotificationCenter.current().delegate = notificationHandler
        ReminderScheduler.shared.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            RootView(storageIsTemporary: storageIsTemporary)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            syncReminders()
        }
    }

    /// Los avisos se rearman al volver a la app: es el momento en que los datos
    /// están al día y no hace falta enganchar cada guardado por separado.
    private func syncReminders() {
        Task { @MainActor in
            let context = ModelContext(container)
            let companions = (try? context.fetch(FetchDescriptor<Companion>())) ?? []
            await ReminderScheduler.shared.sync(companions: companions)
        }
    }
}
