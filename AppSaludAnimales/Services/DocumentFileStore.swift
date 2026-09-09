import Foundation
import UniformTypeIdentifiers

/// Escribe un documento guardado a un archivo temporal para poder verlo y
/// compartirlo.
///
/// El original vive en la base de datos de la app; esto es una copia efímera que
/// el sistema limpia solo.
enum DocumentFileStore {
    /// Qué se puede adjuntar: cualquier archivo.
    ///
    /// Antes la app aceptaba solo PDF, imágenes y texto plano. Un archivo de
    /// salud de años no es tan prolijo: hay informes en Word, planillas de
    /// seguimiento, escaneos en formatos raros de la máquina del veterinario.
    /// Filtrar por tipo no protegía de nada —el archivo se guarda igual como
    /// bytes— y dejaba afuera documentos legítimos, que es el único error que
    /// importa acá. Lo que sí se controla es el tamaño.
    static let importableTypes: [UTType] = [.data]

    /// Cada documento vive adentro de la base de datos de la app. Un archivo muy
    /// grande no se nota al guardarlo y se nota después, cuando la app ocupa
    /// varios gigabytes y nadie sabe por qué.
    static let maximumFileByteCount = 25 * 1024 * 1024

    static func isWithinSizeLimit(_ data: Data) -> Bool {
        data.count <= maximumFileByteCount
    }

    static var sizeLimitDescription: String {
        ByteCountFormatter.string(
            fromByteCount: Int64(maximumFileByteCount),
            countStyle: .file
        )
    }

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
