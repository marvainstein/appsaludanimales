import SwiftUI

/// Tipografía del producto.
///
/// Todos los estilos derivan de los estilos de texto del sistema, nunca de
/// tamaños fijos: es lo que permite que Dynamic Type funcione hasta los tamaños
/// de accesibilidad más grandes sin romper la interfaz.
enum AppFont {
    static let screenTitle = Font.largeTitle.weight(.semibold)
    static let sectionTitle = Font.title3.weight(.semibold)
    static let cardTitle = Font.headline
    static let body = Font.body
    static let secondary = Font.subheadline
    static let caption = Font.footnote
    static let chip = Font.footnote.weight(.semibold)

    /// El modo emergencia se lee de un vistazo, con el pulso acelerado y a veces
    /// con el teléfono en la mano de otra persona: un escalón más grande que el
    /// resto de la app, sin dejar de responder a Dynamic Type.
    enum Emergency {
        static let name = Font.largeTitle.weight(.bold)
        static let sectionTitle = Font.title3.weight(.semibold)
        static let value = Font.title3
        static let label = Font.subheadline.weight(.semibold)
    }
}

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    /// Área mínima recomendada para cualquier control táctil.
    static let minimumTapTarget: CGFloat = 44
}

enum Radius {
    static let card: CGFloat = 16
    static let control: CGFloat = 12
}
