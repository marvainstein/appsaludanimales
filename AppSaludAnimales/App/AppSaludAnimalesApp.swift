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

    /// Las pruebas que auditan pantallas de adentro arrancan con un compañero ya
    /// cargado. Hacerlas pasar por la bienvenida escribiendo en un campo las
    /// volvía frágiles por algo que no tiene nada que ver con lo que miden.
    private static var shouldSeedCompanion: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiTestingSeedCompanion")
    }

    init() {
        if Self.isRunningUITests,
           let container = try? ModelContainerFactory.makeContainer(inMemory: true) {
            self.container = container
            self.storageIsTemporary = false

            if Self.shouldSeedCompanion {
                Self.seedCompanion(in: container)
            }
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

    private static func seedCompanion(in container: ModelContainer) {
        let context = ModelContext(container)
        context.insert(Companion(name: "Luli", species: .dog))
        try? context.save()
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
