import Foundation

/// Períodos que se pueden pedir en un resumen.
enum ReportPeriod: String, CaseIterable, Identifiable, Sendable {
    case week
    case month
    case quarter
    case year
    case all

    var id: String { rawValue }

    var label: String {
        switch self {
        case .week: String(localized: "7 días")
        case .month: String(localized: "30 días")
        case .quarter: String(localized: "3 meses")
        case .year: String(localized: "1 año")
        case .all: String(localized: "Todo")
        }
    }

    var days: Int? {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        case .year: 365
        case .all: nil
        }
    }

    var description: String {
        switch self {
        case .all: String(localized: "Historia completa")
        default: String(localized: "Últimos \(label)")
        }
    }
}

/// Qué incluir en el resumen. La persona elige: lo que se comparte con un
/// veterinario no siempre es todo.
enum ReportSectionKind: String, CaseIterable, Identifiable, Sendable {
    case basics
    case contacts
    case criticalHealth
    case currentCare
    case vaccinations
    case episodes
    case weight
    case history

    var id: String { rawValue }

    var label: String {
        switch self {
        case .basics: String(localized: "Datos básicos")
        case .contacts: String(localized: "Contactos")
        case .criticalHealth: String(localized: "Alergias y condiciones")
        case .currentCare: String(localized: "Medicaciones y tratamientos actuales")
        case .vaccinations: String(localized: "Vacunas")
        case .episodes: String(localized: "Episodios")
        case .weight: String(localized: "Peso")
        case .history: String(localized: "Historial del período")
        }
    }

    /// Lo que casi siempre quiere ver un veterinario, marcado de entrada.
    var isOnByDefault: Bool {
        self != .contacts
    }
}

struct HealthReport: Equatable {
    struct Line: Equatable {
        let text: String
        var detail: String?
    }

    struct Section: Equatable {
        let title: String
        let lines: [Line]
    }

    let companionName: String
    let subtitle: String
    let periodDescription: String
    let generatedOn: Date
    let sections: [Section]
}

/// Arma el resumen a partir de lo registrado, y solo de eso.
///
/// No interpreta, no infiere y no concluye: ordena lo que la persona anotó para
/// que se pueda leer de corrido. Cualquier lectura clínica la hace un
/// profesional.
enum HealthReportBuilder {
    static func report(
        for companion: Companion,
        period: ReportPeriod,
        sections selectedSections: Set<ReportSectionKind>,
        on referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> HealthReport {
        let start = startDate(for: period, on: referenceDate, calendar: calendar)

        let sections = ReportSectionKind.allCases
            .filter(selectedSections.contains)
            .compactMap { kind in
                section(
                    kind,
                    for: companion,
                    from: start,
                    to: referenceDate,
                    calendar: calendar
                )
            }

        return HealthReport(
            companionName: companion.displayName,
            subtitle: subtitle(for: companion),
            periodDescription: period.description,
            generatedOn: referenceDate,
            sections: sections
        )
    }

    static func startDate(
        for period: ReportPeriod,
        on referenceDate: Date,
        calendar: Calendar
    ) -> Date? {
        guard let days = period.days else { return nil }
        return calendar.date(byAdding: .day, value: -days, to: referenceDate)
    }

    // MARK: - Secciones

    private static func section(
        _ kind: ReportSectionKind,
        for companion: Companion,
        from start: Date?,
        to end: Date,
        calendar: Calendar
    ) -> HealthReport.Section? {
        let lines: [HealthReport.Line]

        switch kind {
        case .basics:
            lines = basicsLines(for: companion)
        case .contacts:
            lines = contactLines(for: companion)
        case .criticalHealth:
            lines = criticalHealthLines(for: companion)
        case .currentCare:
            lines = currentCareLines(for: companion, on: end)
        case .vaccinations:
            lines = vaccinationLines(for: companion)
        case .episodes:
            lines = episodeLines(for: companion, from: start, to: end)
        case .weight:
            lines = weightLines(for: companion, from: start, to: end)
        case .history:
            lines = historyLines(for: companion, from: start, to: end)
        }

        guard !lines.isEmpty else { return nil }

        return HealthReport.Section(title: kind.label, lines: lines)
    }

    private static func basicsLines(for companion: Companion) -> [HealthReport.Line] {
        var lines: [HealthReport.Line] = [
            HealthReport.Line(text: String(localized: "Nombre"), detail: companion.name)
        ]

        if let nickname = companion.nickname, !nickname.isEmpty {
            lines.append(HealthReport.Line(text: String(localized: "Apodo"), detail: nickname))
        }

        lines.append(
            HealthReport.Line(text: String(localized: "Especie"), detail: companion.species.label)
        )

        if let breed = companion.breed, !breed.isEmpty {
            lines.append(HealthReport.Line(text: String(localized: "Raza"), detail: breed))
        }

        lines.append(HealthReport.Line(text: String(localized: "Sexo"), detail: companion.sex.label))

        if let age = companion.age {
            lines.append(HealthReport.Line(text: String(localized: "Edad"), detail: age.formatted))
        }

        if let birthDate = companion.birthDate {
            let formatted = DateDescription.absolute(birthDate)
            lines.append(
                HealthReport.Line(
                    text: String(localized: "Fecha de cumpleaños"),
                    detail: companion.birthDatePrecision.isApproximate
                        ? String(localized: "\(formatted) (aproximada)")
                        : formatted
                )
            )
        }

        return lines
    }

    private static func contactLines(for companion: Companion) -> [HealthReport.Line] {
        let profile = EmergencyProfileBuilder.profile(for: companion)
        var lines: [HealthReport.Line] = []

        // Todas las veterinarias guardadas, no solo la de cabecera: este papel
        // termina en la mano de alguien que quizá necesite llamar a la que
        // atendió la urgencia y no a la que lleva la historia.
        for veterinarian in profile.veterinarians {
            lines.append(
                HealthReport.Line(
                    text: veterinarian.isPrimary
                        ? String(localized: "Veterinaria de cabecera")
                        : String(localized: "Veterinaria"),
                    detail: [veterinarian.name, veterinarian.phone]
                        .compactMap { $0 }
                        .joined(separator: " · ")
                )
            )
        }

        for person in profile.responsiblePeople {
            lines.append(
                HealthReport.Line(
                    text: String(localized: "Persona a cargo"),
                    detail: [person.name, person.phone]
                        .compactMap { $0 }
                        .joined(separator: " · ")
                )
            )
        }

        return lines
    }

    private static func criticalHealthLines(for companion: Companion) -> [HealthReport.Line] {
        var lines: [HealthReport.Line] = []

        if let allergies = companion.allergies, !allergies.isEmpty {
            lines.append(HealthReport.Line(text: String(localized: "Alergias"), detail: allergies))
        }

        if let conditions = companion.relevantConditions, !conditions.isEmpty {
            lines.append(
                HealthReport.Line(text: String(localized: "Condiciones"), detail: conditions)
            )
        }

        return lines
    }

    private static func currentCareLines(
        for companion: Companion,
        on referenceDate: Date
    ) -> [HealthReport.Line] {
        var lines: [HealthReport.Line] = []

        for medication in companion.activeMedications(on: referenceDate).sorted(by: { $0.name < $1.name }) {
            var parts: [String] = []

            // "Ahora" y no la dosis a secas: pegada a la fecha de inicio se leía
            // como que venía tomando eso desde entonces, y una dosis cambia. Lo
            // que pasó de verdad está en el historial, toma por toma.
            if let dose = medication.dose, !dose.isEmpty {
                parts.append(String(localized: "ahora \(dose)"))
            }

            if !medication.timesOfDay.isEmpty {
                parts.append(medication.timesOfDay.map(\.label).joined(separator: ", "))
            }

            parts.append(
                String(localized: "empezó el \(DateDescription.absolute(medication.startDate))")
            )

            lines.append(
                HealthReport.Line(
                    text: medication.name,
                    detail: parts.joined(separator: " · ")
                )
            )
        }

        for treatment in companion.activeTreatments(on: referenceDate).sorted(by: { $0.name < $1.name }) {
            lines.append(
                HealthReport.Line(
                    text: treatment.name,
                    detail: String(localized: "empezó el \(DateDescription.absolute(treatment.startDate))")
                )
            )
        }

        return lines
    }

    private static func vaccinationLines(for companion: Companion) -> [HealthReport.Line] {
        companion.vaccinations
            .sorted { $0.date > $1.date }
            .map { vaccination in
                var detail = DateDescription.absolute(vaccination.date)

                if let next = vaccination.nextDueDate {
                    detail += " · " + String(
                        localized: "próxima: \(DateDescription.absolute(next))"
                    )
                }

                return HealthReport.Line(text: vaccination.name, detail: detail)
            }
    }

    private static func episodeLines(
        for companion: Companion,
        from start: Date?,
        to end: Date
    ) -> [HealthReport.Line] {
        companion.episodes
            .filter { isInPeriod($0.date, from: start, to: end) }
            .sorted { $0.date > $1.date }
            .map { episode in
                var parts = [DateDescription.absolute(episode.date), episode.status.label]

                if let intensity = episode.intensity {
                    parts.append(intensity.label)
                }

                if let description = episode.episodeDescription, !description.isEmpty {
                    parts.append(description)
                }

                return HealthReport.Line(
                    text: episode.symptom,
                    detail: parts.joined(separator: " · ")
                )
            }
    }

    private static func weightLines(
        for companion: Companion,
        from start: Date?,
        to end: Date
    ) -> [HealthReport.Line] {
        let measurements = companion.measurements
            .filter { $0.kind == .weight && isInPeriod($0.date, from: start, to: end) }
            .sorted { $0.date > $1.date }

        guard !measurements.isEmpty else { return [] }

        var lines = measurements.map { measurement in
            HealthReport.Line(
                text: measurement.formattedValue,
                detail: DateDescription.absolute(measurement.date)
            )
        }

        // El resumen en palabras va primero: un profesional no debería tener que
        // restar dos números de una lista para ver la tendencia.
        if let newest = measurements.first, let oldest = measurements.last, measurements.count > 1 {
            let difference = newest.value - oldest.value
            let formatted = abs(difference).formatted(.number.precision(.fractionLength(0...2)))
            let direction = difference < 0
                ? String(localized: "bajó \(formatted) \(newest.unit)")
                : String(localized: "subió \(formatted) \(newest.unit)")

            lines.insert(
                HealthReport.Line(
                    text: String(localized: "Variación en el período"),
                    detail: difference == 0
                        ? String(localized: "sin cambios")
                        : direction
                ),
                at: 0
            )
        }

        return lines
    }

    private static func historyLines(
        for companion: Companion,
        from start: Date?,
        to end: Date
    ) -> [HealthReport.Line] {
        // Por cambios y no toma por toma. Exportar toda la historia de un animal
        // con una línea por cada pastilla son miles de renglones que repiten lo
        // mismo; lo que importa es cuándo cambió algo. Si entre dos renglones no
        // hay nada, es porque siguió igual, y esa ausencia dice tanto como el
        // dato.
        HistoryBuilder.entries(for: companion, rhythm: .byChange)
            .filter { isInPeriod($0.date, from: start, to: end) }
            .map { entry in
                HealthReport.Line(
                    text: "\(entry.category.label): \(entry.title)",
                    detail: [DateDescription.absolute(entry.date), entry.detail]
                        .compactMap { $0 }
                        .joined(separator: " · ")
                )
            }
    }

    private static func isInPeriod(_ date: Date, from start: Date?, to end: Date) -> Bool {
        guard date <= end else { return false }
        guard let start else { return true }
        return date >= start
    }

    private static func subtitle(for companion: Companion) -> String {
        guard let age = companion.age else { return companion.species.label }
        return "\(companion.species.label) · \(age.formatted)"
    }
}
