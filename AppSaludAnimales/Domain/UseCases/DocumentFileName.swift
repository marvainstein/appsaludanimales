import Foundation

/// Nombres de archivo para compartir un documento.
///
/// Lo que se comparte con un veterinario tiene que llegar con un nombre que se
/// entienda —"Luli - Análisis de sangre.pdf"— y no con el nombre críptico que
/// traía el archivo original.
enum DocumentFileName {
    static let fallbackName = "Documento"

    /// Caracteres que rompen un nombre de archivo en algún sistema.
    private static let forbidden = CharacterSet(charactersIn: "/\\:*?\"<>|\n\r\t")

    static func make(
        companionName: String,
        title: String,
        originalFileName: String?,
        defaultExtension: String
    ) -> String {
        let base = [companionName, title]
            .map(sanitize)
            .filter { !$0.isEmpty }
            .joined(separator: " - ")

        let name = base.isEmpty ? fallbackName : base

        return "\(name).\(fileExtension(originalFileName: originalFileName, fallback: defaultExtension))"
    }

    static func sanitize(_ value: String) -> String {
        value
            .components(separatedBy: forbidden)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
    }

    private static func fileExtension(originalFileName: String?, fallback: String) -> String {
        guard let originalFileName else { return fallback }

        let pathExtension = (originalFileName as NSString).pathExtension
        return pathExtension.isEmpty ? fallback : pathExtension.lowercased()
    }
}

/// Categorías que la app ofrece como sugerencia al adjuntar. Es una ayuda para
/// escribir menos, no una lista cerrada.
enum DocumentCategorySuggestions {
    static let all: [String] = [
        String(localized: "Análisis"),
        String(localized: "Radiografía"),
        String(localized: "Ecografía"),
        String(localized: "Receta"),
        String(localized: "Informe"),
        String(localized: "Indicaciones"),
        String(localized: "Certificado"),
        String(localized: "Foto")
    ]
}
