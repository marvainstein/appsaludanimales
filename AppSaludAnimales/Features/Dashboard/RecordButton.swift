import SwiftUI

/// El botón de registrar, que acompaña mientras se recorre el dashboard.
///
/// Registrar es la acción central del producto y tiene que estar siempre a mano:
/// si hay que volver arriba para anotar algo, se anota menos. Pero un botón de
/// ancho completo pegado abajo se come una franja de pantalla todo el tiempo.
///
/// La salida es que se presente entero —con su palabra, para que se entienda qué
/// hace— y se achique a un círculo apenas se empieza a bajar, cuando ya se leyó.
/// Lo que cambia es el dibujo, no el botón: para VoiceOver sigue diciendo
/// "Registrar" en los dos estados, porque quien no ve la pantalla no tiene por
/// qué enterarse de que se encogió.
struct RecordButton: View {
    let isCompact: Bool
    let action: () -> Void

    /// El círculo crece con el tamaño de texto elegido en el sistema: si no,
    /// sería lo único de la pantalla que se queda chico.
    @ScaledMetric(relativeTo: .headline) private var compactDiameter: CGFloat = 60

    var body: some View {
        HStack(spacing: 0) {
            if isCompact {
                Spacer(minLength: 0)
            }

            Button(action: action) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "plus")
                        .accessibilityHidden(true)

                    if !isCompact {
                        Text("Registrar")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .font(AppFont.cardTitle)
                .foregroundStyle(Palette.onAccentFill)
                .frame(
                    maxWidth: isCompact ? nil : .infinity,
                    minHeight: Spacing.minimumTapTarget
                )
                .frame(
                    width: isCompact ? compactDiameter : nil,
                    height: isCompact ? compactDiameter : nil
                )
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Palette.accentFill)
            .shadow(color: .black.opacity(isCompact ? 0.18 : 0), radius: 8, y: 3)
            .accessibilityLabel(Text("Registrar"))
            .accessibilityHint(Text("Anotar una medicación, un síntoma, el peso, una vacuna o una nota"))
            .accessibilityIdentifier("dashboard.record")
        }
    }
}
