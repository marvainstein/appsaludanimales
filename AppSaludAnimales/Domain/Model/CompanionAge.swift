import Foundation

/// Edad derivada de la fecha de nacimiento y de su precisión.
///
/// `isApproximate` nunca se pierde: toda presentación de la edad debe comunicar
/// si el dato es estimado, en texto, no solo visualmente.
struct CompanionAge: Equatable, Sendable {
    var years: Int
    var months: Int
    var isApproximate: Bool

    /// Texto listo para mostrar y para leer con VoiceOver.
    var formatted: String {
        let base: String
        switch (years, months) {
        case (0, 0):
            base = String(localized: "menos de un mes")
        case (0, let months):
            base = months == 1
                ? String(localized: "1 mes")
                : String(localized: "\(months) meses")
        case (let years, 0):
            base = years == 1
                ? String(localized: "1 año")
                : String(localized: "\(years) años")
        case (let years, let months):
            let yearsText = years == 1
                ? String(localized: "1 año")
                : String(localized: "\(years) años")
            let monthsText = months == 1
                ? String(localized: "1 mes")
                : String(localized: "\(months) meses")
            base = String(localized: "\(yearsText) y \(monthsText)")
        }

        return isApproximate
            ? String(localized: "Aproximadamente \(base)")
            : base.prefix(1).uppercased() + base.dropFirst()
    }
}

enum CompanionAgeCalculator {
    /// Devuelve `nil` cuando no se conoce la fecha de nacimiento: la ausencia de
    /// edad es un estado válido, no un error a completar.
    static func age(
        birthDate: Date?,
        precision: BirthDatePrecision,
        on referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> CompanionAge? {
        guard precision != .unknown, let birthDate, birthDate <= referenceDate else {
            return nil
        }

        let components = calendar.dateComponents([.year, .month], from: birthDate, to: referenceDate)

        return CompanionAge(
            years: components.year ?? 0,
            months: components.month ?? 0,
            isApproximate: precision.isApproximate
        )
    }

    /// Próximo cumpleaños a partir de la fecha registrada. Para fechas
    /// aproximadas sigue siendo útil como celebración, no como dato clínico.
    static func nextBirthday(
        birthDate: Date?,
        on referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Date? {
        guard let birthDate else { return nil }

        let birthComponents = calendar.dateComponents([.month, .day], from: birthDate)
        return calendar.nextDate(
            after: referenceDate,
            matching: birthComponents,
            matchingPolicy: .nextTimePreservingSmallerComponents
        )
    }
}
