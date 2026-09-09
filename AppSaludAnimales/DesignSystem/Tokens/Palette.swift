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
    /// No puede ser el mismo que el de texto, y confundirlos costó caro: el
    /// botón principal quedaba blanco sobre un color claro en modo oscuro, con
    /// un contraste de 2,3 a 1 sobre un mínimo de 4,5. Ilegible, y en la
    /// pantalla más usada de la app.
    static let accentFill = ColorPair(light: 0xA0472C, dark: 0xAA4E2E)
    static let onAccentFill = ColorPair(light: 0xFFFFFF, dark: 0xFFFFFF)

    static let accentSoft = ColorPair(light: 0xF2E1D8, dark: 0x46281C)
    static let onAccentSoft = ColorPair(light: 0x7A3520, dark: 0xF0C4B0)
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
