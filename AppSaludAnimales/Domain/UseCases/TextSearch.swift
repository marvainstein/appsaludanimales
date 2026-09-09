import Foundation

/// Buscar texto como lo escribe una persona apurada.
///
/// Sin tildes y sin distinguir mayúsculas: quien busca "analisis" en el teclado
/// del teléfono está buscando "Análisis", y hacerle poner la tilde para
/// encontrarlo es cobrarle un peaje por apurarse. En una app en castellano esto
/// no es un detalle: es la diferencia entre que la búsqueda sirva o no.
enum TextSearch {
    static func matches(_ text: String?, query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else { return true }
        guard let text, !text.isEmpty else { return false }

        return text.range(
            of: trimmedQuery,
            options: [.caseInsensitive, .diacriticInsensitive]
        ) != nil
    }

    /// Busca en varios campos a la vez: alcanza con que aparezca en alguno.
    static func matchesAny(_ texts: [String?], query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else { return true }

        return texts.contains { matches($0, query: trimmedQuery) }
    }
}
