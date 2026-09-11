import SwiftData
import SwiftUI

/// Leer un respaldo y cargarlo.
///
/// Vive aparte porque hacen falta dos puertas a lo mismo. La de Respaldo, para
/// quien ya está usando la app. Y la de la bienvenida, para quien acaba de
/// cambiar de teléfono: sin ella había que inventar un animal para poder
/// recuperar los propios, y esa persona terminaba con un compañero fantasma al
/// lado de los suyos.
enum RestoreFromFile {
    enum Outcome {
        case restored(BackupRestoreSummary)
        case failed(String)
    }

    static func load(_ result: Result<[URL], Error>, into context: ModelContext) -> Outcome? {
        guard case let .success(urls) = result, let url = urls.first else { return nil }

        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let archive = try BackupService.decode(data)
            let summary = try BackupService.restore(archive, into: context)
            ReminderSync.refresh(using: context)
            return .restored(summary)
        } catch let error as BackupError {
            return .failed(error.errorDescription ?? unreadable)
        } catch {
            return .failed(unreadable)
        }
    }

    private static var unreadable: String {
        String(localized: "No pudimos leer ese archivo. Fijate que sea el respaldo que bajaste de esta app.")
    }
}
