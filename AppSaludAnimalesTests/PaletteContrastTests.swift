import Foundation
import Testing

@testable import AppSaludAnimales

/// El contraste de la paleta, verificado y no prometido.
///
/// Decir "contraste verificado" en un comentario no verifica nada: el día que
/// alguien cambia un color porque le gusta más, el comentario sigue diciendo lo
/// mismo y la app ya no se lee. Acá el mínimo se calcula sobre los valores
/// reales, y si un color baja del umbral esta prueba falla antes de que llegue a
/// nadie.
///
/// El umbral es 4.5 a 1, que es el mínimo de la norma para texto normal.
struct PaletteContrastTests {
    private let minimumForText = 4.5

    @Test("El texto se lee sobre todos los fondos, en claro y en oscuro")
    func elTextoSeLeeSobreTodosLosFondos() {
        let foregrounds: [(String, ColorPair)] = [
            ("texto", PaletteValues.ink),
            ("texto secundario", PaletteValues.inkMuted),
            ("acento", PaletteValues.accent)
        ]

        let backgrounds: [(String, ColorPair)] = [
            ("fondo", PaletteValues.background),
            ("superficie", PaletteValues.surface),
            ("superficie apagada", PaletteValues.surfaceMuted)
        ]

        for (foregroundName, foreground) in foregrounds {
            for (backgroundName, background) in backgrounds {
                expectReadable(
                    foreground,
                    on: background,
                    description: "\(foregroundName) sobre \(backgroundName)"
                )
            }
        }
    }

    /// El caso que se escapó una vez: el color de relleno del botón principal
    /// no es el mismo que el de texto, y llevarlos juntos por error dejó el
    /// botón en 2,3 a 1 en modo oscuro.
    @Test("El botón principal se lee con sus letras encima")
    func elBotonPrincipalSeLee() {
        expectReadable(
            PaletteValues.onAccentFill,
            on: PaletteValues.accentFill,
            description: "letras del botón principal"
        )
    }

    @Test("El acento suave se lee con su propio texto encima")
    func elAcentoSuaveSeLee() {
        expectReadable(
            PaletteValues.onAccentSoft,
            on: PaletteValues.accentSoft,
            description: "texto del acento suave"
        )
    }

    /// Los indicadores de estado son lo que más se mira de reojo y con apuro.
    @Test("Cada indicador de estado se lee sobre su propio fondo")
    func losIndicadoresDeEstadoSeLeen() {
        for tone in [StatusTone.neutral, .positive, .attention, .critical] {
            expectReadable(
                tone.contentValues,
                on: tone.softBackgroundValues,
                description: "estado \(tone)"
            )
        }
    }

    // MARK: - Cálculo

    private func expectReadable(
        _ foreground: ColorPair,
        on background: ColorPair,
        description: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let light = contrastRatio(foreground.light, background.light)
        let dark = contrastRatio(foreground.dark, background.dark)

        #expect(
            light >= minimumForText,
            "En modo claro, \(description) queda en \(rounded(light)) a 1 y el mínimo es \(minimumForText)",
            sourceLocation: sourceLocation
        )

        #expect(
            dark >= minimumForText,
            "En modo oscuro, \(description) queda en \(rounded(dark)) a 1 y el mínimo es \(minimumForText)",
            sourceLocation: sourceLocation
        )
    }

    /// Contraste según la fórmula de la norma de accesibilidad para contenido
    /// web, que es la que usan también las herramientas de Apple.
    private func contrastRatio(_ first: UInt32, _ second: UInt32) -> Double {
        let a = relativeLuminance(first)
        let b = relativeLuminance(second)

        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    private func relativeLuminance(_ hex: UInt32) -> Double {
        let channels = [16, 8, 0].map { shift -> Double in
            let value = Double((hex >> UInt32(shift)) & 0xFF) / 255

            return value <= 0.03928
                ? value / 12.92
                : pow((value + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
    }

    private func rounded(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }
}
