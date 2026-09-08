import Foundation

/// Un documento elegido para importar, todavía sin guardar.
///
/// Entre elegir treinta archivos y guardarlos hay un paso obligatorio: repasar
/// qué es cada uno. Treinta documentos sin título ni fecha son treinta
/// registros que no se van a poder encontrar después, y el archivo mal
/// ordenado es justamente el problema del que se venía escapando.
struct DocumentImportDraft: Identifiable {
    let id: UUID
    var title: String
    var category: String
    var date: Date
    let fileName: String?
    let contentTypeIdentifier: String?
    let data: Data

    init(
        id: UUID = UUID(),
        title: String,
        category: String = "",
        date: Date,
        fileName: String?,
        contentTypeIdentifier: String?,
        data: Data
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.date = date
        self.fileName = fileName
        self.contentTypeIdentifier = contentTypeIdentifier
        self.data = data
    }

    var isReady: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Traer varios documentos de una.
///
/// El caso real: alguien con años de estudios ya clasificados afuera de la app.
/// Pasarlos de a uno es inviable, y si la única forma de empezar es esa, no se
/// empieza. Acá la app hace el trabajo aburrido —proponer un título y descubrir
/// la fecha a partir del nombre del archivo— y deja a la persona solo lo que
/// una máquina no puede saber.
enum DocumentBatchImport {
    /// Cada documento se guarda entero adentro de la app. Traer cientos de una
    /// vez llenaría el teléfono sin que se note hasta que es tarde.
    static let maximumFiles = 40

    static func draft(
        fileName: String?,
        data: Data,
        contentTypeIdentifier: String?,
        fallbackDate: Date = Date(),
        calendar: Calendar = .current
    ) -> DocumentImportDraft {
        // La extensión se saca primero: "2024-03-12.pdf" tiene que quedar sin
        // título propuesto, no con "Pdf".
        let baseName = fileName.map { ($0 as NSString).deletingPathExtension }
        let detected = baseName.flatMap {
            detectedDate(in: $0, calendar: calendar, now: fallbackDate)
        }

        return DocumentImportDraft(
            title: suggestedTitle(fromBaseName: baseName, removing: detected?.range),
            date: detected?.date ?? fallbackDate,
            fileName: fileName,
            contentTypeIdentifier: contentTypeIdentifier,
            data: data
        )
    }

    // MARK: - Título

    /// Propone un título a partir del nombre del archivo.
    ///
    /// "analisis_sangre_2024-03-12" es información real mal presentada: dice qué
    /// es y cuándo fue. Se le sacan la fecha ya reconocida y los guiones bajos,
    /// y queda "Analisis sangre", que casi siempre alcanza. Si no queda nada
    /// —un archivo llamado solo con su fecha— el título se deja vacío: la app no
    /// sabe qué es ese documento y fingir que sí lo vuelve imposible de
    /// encontrar después.
    static func suggestedTitle(
        fromBaseName baseName: String?,
        removing dateRange: Range<String.Index>? = nil
    ) -> String {
        guard let baseName else { return "" }

        var base = baseName
        if let dateRange {
            base.removeSubrange(dateRange)
        }

        let spaced = base
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: ".", with: " ")

        let collapsed = spaced
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")

        let clean = DocumentFileName.sanitize(collapsed)
        guard let first = clean.first else { return "" }

        return first.uppercased() + clean.dropFirst()
    }

    // MARK: - Fecha

    struct DetectedDate {
        let date: Date
        /// Dónde estaba escrita, para poder sacarla del título propuesto.
        let range: Range<String.Index>
    }

    /// Busca una fecha adentro del nombre del archivo.
    ///
    /// Los estudios guardados a lo largo de los años casi siempre traen la fecha
    /// en el nombre, y es el dato más tedioso de cargar a mano treinta veces.
    ///
    /// Reconoce `2024-03-12`, `12-03-2024` y `20240312`, con guiones, guiones
    /// bajos, puntos o nada en el medio. Cuando el año va primero se lee como
    /// año-mes-día; cuando va último, como día-mes-año, que es como se escribe
    /// acá. Una fecha imposible o futura se descarta: un estudio no puede ser de
    /// mañana, y equivocarse en silencio es peor que no adivinar.
    static func detectedDate(
        in fileName: String,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> DetectedDate? {
        let groups = digitGroups(in: fileName)

        for (index, group) in groups.enumerated() {
            // 20240312
            if group.digits.count == 8 {
                let text = group.digits
                if let date = makeDate(
                    year: Int(text.prefix(4)),
                    month: Int(text.dropFirst(4).prefix(2)),
                    day: Int(text.suffix(2)),
                    calendar: calendar,
                    now: now
                ) {
                    return DetectedDate(date: date, range: group.range)
                }
            }

            // 2024-03-12 o 12-03-2024, con un solo separador entre cada parte.
            guard index + 2 < groups.count else { continue }

            let second = groups[index + 1]
            let third = groups[index + 2]

            guard
                isSingleSeparator(between: group, and: second, in: fileName),
                isSingleSeparator(between: second, and: third, in: fileName)
            else {
                continue
            }

            let lengths = (group.digits.count, second.digits.count, third.digits.count)
            let range = group.range.lowerBound..<third.range.upperBound

            if lengths == (4, 2, 2), let date = makeDate(
                year: Int(group.digits),
                month: Int(second.digits),
                day: Int(third.digits),
                calendar: calendar,
                now: now
            ) {
                return DetectedDate(date: date, range: range)
            }

            if lengths == (2, 2, 4), let date = makeDate(
                year: Int(third.digits),
                month: Int(second.digits),
                day: Int(group.digits),
                calendar: calendar,
                now: now
            ) {
                return DetectedDate(date: date, range: range)
            }
        }

        return nil
    }

    // MARK: - Resumen

    /// Lo que falta, dicho sin reproche: es una lista de trabajo pendiente, no
    /// un error de quien la está completando.
    static func pendingTitleMessage(for drafts: [DocumentImportDraft]) -> String? {
        let missing = drafts.filter { !$0.isReady }.count
        guard missing > 0 else { return nil }

        return missing == 1
            ? String(localized: "Falta el título de 1 documento.")
            : String(localized: "Faltan los títulos de \(missing) documentos.")
    }

    static func saveButtonTitle(for drafts: [DocumentImportDraft]) -> String {
        drafts.count == 1
            ? String(localized: "Guardar el documento")
            : String(localized: "Guardar los \(drafts.count) documentos")
    }

    // MARK: - Interno

    private struct DigitGroup {
        let digits: String
        let range: Range<String.Index>
    }

    private static func digitGroups(in text: String) -> [DigitGroup] {
        var groups: [DigitGroup] = []
        var start: String.Index?

        for index in text.indices {
            if text[index].isNumber {
                if start == nil { start = index }
            } else if let begin = start {
                groups.append(DigitGroup(digits: String(text[begin..<index]), range: begin..<index))
                start = nil
            }
        }

        if let begin = start {
            groups.append(DigitGroup(digits: String(text[begin...]), range: begin..<text.endIndex))
        }

        return groups
    }

    private static func isSingleSeparator(
        between first: DigitGroup,
        and second: DigitGroup,
        in text: String
    ) -> Bool {
        text.distance(from: first.range.upperBound, to: second.range.lowerBound) == 1
    }

    private static func makeDate(
        year: Int?,
        month: Int?,
        day: Int?,
        calendar: Calendar,
        now: Date
    ) -> Date? {
        guard
            let year, let month, let day,
            (1990...2100).contains(year),
            (1...12).contains(month),
            (1...31).contains(day)
        else {
            return nil
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12

        guard
            let date = calendar.date(from: components),
            calendar.component(.day, from: date) == day,
            calendar.component(.month, from: date) == month,
            date <= now
        else {
            return nil
        }

        return date
    }
}
