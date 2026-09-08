import SwiftData
import Foundation

/// Rearma los avisos después de un cambio que los afecta.
///
/// Los avisos se rearmaban solo al volver a la app. En la práctica casi siempre
/// alcanzaba —se guarda una medicación y se bloquea el teléfono—, pero "casi
/// siempre" no sirve para algo que existe para que no se olvide una dosis: si
/// alguien guarda, sigue usando la app y la deja abierta, el aviso no estaba.
///
/// Lo mismo al revés: al eliminar o suspender una medicación, el aviso seguía
/// programado hasta la próxima vez que se abriera la app. Avisar por algo que ya
/// no existe es peor que no avisar, porque enseña a desconfiar del aviso.
enum ReminderSync {
    @MainActor
    static func refresh(using context: ModelContext) {
        let companions = (try? context.fetch(FetchDescriptor<Companion>())) ?? []

        Task {
            await ReminderScheduler.shared.sync(companions: companions)
        }
    }
}
