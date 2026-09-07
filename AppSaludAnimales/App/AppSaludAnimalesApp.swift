import SwiftData
import SwiftUI

@main
struct AppSaludAnimalesApp: App {
    private let container: ModelContainer

    /// Cuando el almacenamiento permanente falla, la app sigue abriendo con un
    /// almacenamiento temporal y lo dice con claridad, en vez de cerrarse.
    private let storageIsTemporary: Bool

    init() {
        if let container = try? ModelContainerFactory.makeContainer() {
            self.container = container
            self.storageIsTemporary = false
        } else {
            self.container = try! ModelContainerFactory.makeContainer(inMemory: true)
            self.storageIsTemporary = true
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(storageIsTemporary: storageIsTemporary)
        }
        .modelContainer(container)
    }
}
