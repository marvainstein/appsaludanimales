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
