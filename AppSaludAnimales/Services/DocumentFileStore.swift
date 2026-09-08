import Foundation
import UniformTypeIdentifiers

/// Escribe un documento guardado a un archivo temporal para poder verlo y
/// compartirlo.
///
/// El original vive en la base de datos de la app; esto es una copia efímera que
/// el sistema limpia solo.
enum DocumentFileStore {
    static func temporaryURL(for document: HealthDocument, companionName: String) -> URL? {
        guard let data = document.fileData else { return nil }

        let fileName = DocumentFileName.make(
            companionName: companionName,
            title: document.title,
            originalFileName: document.fileName,
            defaultExtension: defaultExtension(for: document)
        )

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    static func isImage(_ document: HealthDocument) -> Bool {
        guard let identifier = document.contentTypeIdentifier else {
            return document.fileName == nil
        }

        return UTType(identifier)?.conforms(to: .image) ?? false
    }

    private static func defaultExtension(for document: HealthDocument) -> String {
        guard
            let identifier = document.contentTypeIdentifier,
            let type = UTType(identifier),
            let preferred = type.preferredFilenameExtension
        else {
            return "dat"
        }

        return preferred
    }
}
