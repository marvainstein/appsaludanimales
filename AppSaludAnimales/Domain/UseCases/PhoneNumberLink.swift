import Foundation

/// Convierte un teléfono escrito a mano en un enlace para llamar.
///
/// La gente anota los teléfonos como quiere: "(011) 4567-8900", "011 4567 8900",
/// "+54 9 11 4567-8900". Todos tienen que poder tocarse para llamar, sobre todo
/// en una emergencia.
enum PhoneNumberLink {
    /// Mínimo de dígitos para considerar que es un teléfono y no una anotación
    /// suelta.
    static let minimumDigits = 3

    static func callURL(for phone: String?) -> URL? {
        guard let phone else { return nil }

        let allowed = CharacterSet(charactersIn: "+0123456789")
        let dialable = String(
            String.UnicodeScalarView(phone.unicodeScalars.filter(allowed.contains))
        )

        let digitCount = dialable.filter(\.isNumber).count
        guard digitCount >= minimumDigits else { return nil }

        return URL(string: "tel:\(dialable)")
    }
}
