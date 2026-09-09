import SwiftUI
import UIKit

/// Un color del producto, con su versión clara y su versión oscura.
///
/// Se guardan como número y no como `Color` para que se puedan verificar: hay
/// una prueba que calcula el contraste real de cada combinación y falla si
/// alguna baja del mínimo. "Contraste verificado" tiene que ser un hecho que se
/// comprueba solo, no una promesa en un comentario.
struct ColorPair: Equatable {
    let light: UInt32
    let dark: UInt32
}

/// Los valores de la paleta, en crudo.
enum PaletteValues {
    static let background = ColorPair(light: 0xF4F1E9, dark: 0x1B1913)
    static let surface = ColorPair(light: 0xFFFFFF, dark: 0x24211A)
    static let surfaceMuted = ColorPair(light: 0xECE7D9, dark: 0x2C281F)
    static let separator = ColorPair(light: 0xDDD6C4, dark: 0x3B3626)

    static let ink = ColorPair(light: 0x2A2721, dark: 0xEDE8DA)
    static let inkMuted = ColorPair(light: 0x5E594C, dark: 0xB4AC97)

    /// Acento para texto e íconos: claro en modo oscuro, para leerse sobre el
    /// fondo.
    static let accent = ColorPair(light: 0xA0472C, dark: 0xE0A188)

    /// Acento para rellenar un botón: oscuro en los dos modos, porque encima
    /// lleva letras blancas.
    ///
    /// **No es el acento global de la app.** Ese, el que usan los botones de la
    /// barra de navegación y los enlaces, es `accent`, y tiene que aclararse en
    /// modo oscuro para leerse sobre el fondo. Ponerlo al revés dejó el botón
    /// "Editar" del perfil sin contraste de noche.
    ///
    /// No puede ser el mismo que el de texto, y confundirlos costó caro: el
    /// botón principal quedaba blanco sobre un color claro en modo oscuro, con
    /// un contraste de 2,3 a 1 sobre un mínimo de 4,5. Ilegible, y en la
    /// pantalla más usada de la app.
    static let accentFill = ColorPair(light: 0xA0472C, dark: 0xAA4E2E)
    static let onAccentFill = ColorPair(light: 0xFFFFFF, dark: 0xFFFFFF)

    static let accentSoft = ColorPair(light: 0xF2E1D8, dark: 0x46281C)
    static let onAccentSoft = ColorPair(light: 0x7A3520, dark: 0xF0C4B0)

    /// La tarjeta de la despedida. Es el único lugar de la app que se sale de la
    /// paleta cálida, a propósito: ese momento no se parece a ningún otro.
    static let farewellCard = ColorPair(light: 0xD4E7F2, dark: 0x1E3340)
    static let onFarewellCard = ColorPair(light: 0x243642, dark: 0xDCEAF3)
    static let onFarewellCardMuted = ColorPair(light: 0x3E5666, dark: 0xA9C4D4)

    /// Superficie apagada sobre el celeste, para los bloques que sobre el fondo
    /// cálido usan `surfaceMuted`.
    static let farewellSurfaceMuted = ColorPair(light: 0xC7E0EE, dark: 0x27404F)

    /// Los colores del arco. Apagados a propósito: es un recuerdo, no una
    /// celebración.
    static let rainbow: [ColorPair] = [
        ColorPair(light: 0xE79E8C, dark: 0xC4735F),
        ColorPair(light: 0xEDC988, dark: 0xC79B57),
        ColorPair(light: 0xB8D3A9, dark: 0x7FA36F),
        ColorPair(light: 0x99C2D6, dark: 0x5F8FA8),
        ColorPair(light: 0xC2AED9, dark: 0x8B77A8)
    ]
}

/// Paleta del producto: neutros cálidos de base y un acento terracota.
///
/// Ningún color transporta información por sí solo: acompaña a texto e ícono.
enum Palette {
    static let background = Color(PaletteValues.background)
    static let surface = Color(PaletteValues.surface)
    static let surfaceMuted = Color(PaletteValues.surfaceMuted)
    static let separator = Color(PaletteValues.separator)

    static let ink = Color(PaletteValues.ink)
    static let inkMuted = Color(PaletteValues.inkMuted)

    static let accent = Color(PaletteValues.accent)
    static let accentFill = Color(PaletteValues.accentFill)
    static let onAccentFill = Color(PaletteValues.onAccentFill)
    static let farewellCard = Color(PaletteValues.farewellCard)
    static let farewellSurfaceMuted = Color(PaletteValues.farewellSurfaceMuted)
    static let onFarewellCard = Color(PaletteValues.onFarewellCard)
    static let onFarewellCardMuted = Color(PaletteValues.onFarewellCardMuted)
    static let rainbow: [Color] = PaletteValues.rainbow.map(Color.init)

    static let accentSoft = Color(PaletteValues.accentSoft)
    static let onAccentSoft = Color(PaletteValues.onAccentSoft)
}

extension StatusTone {
    /// Fondo del indicador de estado.
    var softBackgroundValues: ColorPair {
        switch self {
        case .neutral: ColorPair(light: 0xECE7D9, dark: 0x2C281F)
        case .positive: ColorPair(light: 0xD8E9DD, dark: 0x1E3A2A)
        case .attention: ColorPair(light: 0xF4E6C9, dark: 0x3B2F17)
        case .critical: ColorPair(light: 0xF6DBD5, dark: 0x45211C)
        }
    }

    /// Texto e ícono del indicador de estado.
    var contentValues: ColorPair {
        switch self {
        case .neutral: ColorPair(light: 0x4F4A3E, dark: 0xCFC7B2)
        case .positive: ColorPair(light: 0x2C5E43, dark: 0x9FD3B4)
        case .attention: ColorPair(light: 0x6F4A11, dark: 0xE2B672)
        case .critical: ColorPair(light: 0x8E3125, dark: 0xF0A093)
        }
    }

    var softBackground: Color { Color(softBackgroundValues) }
    var content: Color { Color(contentValues) }
}

extension Color {
    /// Color que responde al modo claro/oscuro del sistema y a los ajustes de
    /// accesibilidad, resuelto en tiempo de dibujo y no fijado al iniciar.
    init(_ pair: ColorPair) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: pair.dark)
                : UIColor(hex: pair.light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
