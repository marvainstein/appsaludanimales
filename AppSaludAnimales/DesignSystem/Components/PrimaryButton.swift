import SwiftUI

/// Botón principal de una pantalla: grande, de ancho completo y con área táctil
/// suficiente para usarse con una sola mano y sin apuntar con precisión.
///
/// Cuando está deshabilitado explica en la pista de accesibilidad qué falta, en
/// vez de dejar a la persona adivinando por qué no responde.
struct PrimaryButton: View {
    let title: String
    var symbolName: String?
    var hint: String?
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let symbolName {
                    Image(systemName: symbolName)
                        .accessibilityHidden(true)
                }

                Text(title)
            }
            .font(AppFont.cardTitle)
            .frame(maxWidth: .infinity, minHeight: Spacing.minimumTapTarget)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isEnabled)
        .accessibilityHint(Text(hint ?? ""))
    }
}

/// Sección de formulario que contiene el botón principal, sin el fondo ni los
/// márgenes que `Form` agrega a una fila común.
struct PrimaryButtonSection: View {
    let title: String
    var hint: String?
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Section {
            PrimaryButton(title: title, hint: hint, isEnabled: isEnabled, action: action)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}
