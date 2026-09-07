import SwiftUI

/// Paleta del producto: neutros cálidos y tonos desaturados, con contraste
/// verificado en modo claro y oscuro.
///
/// Ningún color transporta información por sí solo: acompaña a texto e ícono.
enum Palette {
    static let background = Color(light: 0xF4F1E9, dark: 0x1B1913)
    static let surface = Color(light: 0xFFFFFF, dark: 0x24211A)
    static let surfaceMuted = Color(light: 0xECE7D9, dark: 0x2C281F)
    static let separator = Color(light: 0xDDD6C4, dark: 0x3B3626)

    static let ink = Color(light: 0x2A2721, dark: 0xEDE8DA)
    static let inkMuted = Color(light: 0x5E594C, dark: 0xB4AC97)

    static let accent = Color(light: 0x35564C, dark: 0x8FB3A3)
    static let accentSoft = Color(light: 0xDCE6DE, dark: 0x2C4640)
    static let onAccentSoft = Color(light: 0x23413A, dark: 0xCFE4DA)
}

extension StatusTone {
    /// Fondo del indicador de estado.
    var softBackground: Color {
        switch self {
        case .neutral: Color(light: 0xECE7D9, dark: 0x2C281F)
        case .positive: Color(light: 0xD8E9DD, dark: 0x1E3A2A)
        case .attention: Color(light: 0xF4E6C9, dark: 0x3B2F17)
        case .critical: Color(light: 0xF6DBD5, dark: 0x45211C)
        }
    }

    /// Texto e ícono del indicador de estado, con contraste suficiente sobre
    /// `softBackground` en ambos modos.
    var content: Color {
        switch self {
        case .neutral: Color(light: 0x4F4A3E, dark: 0xCFC7B2)
        case .positive: Color(light: 0x2C5E43, dark: 0x9FD3B4)
        case .attention: Color(light: 0x6F4A11, dark: 0xE2B672)
        case .critical: Color(light: 0x8E3125, dark: 0xF0A093)
        }
    }
}

extension Color {
    /// Color que responde al modo claro/oscuro del sistema y a los ajustes de
    /// accesibilidad, resuelto en tiempo de dibujo y no fijado al iniciar.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
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
