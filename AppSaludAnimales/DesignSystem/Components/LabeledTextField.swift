import SwiftUI
import UIKit

/// Campo de texto con su etiqueta siempre visible.
///
/// No se usa el texto de ejemplo dentro del campo como única etiqueta: desaparece
/// al escribir, y VoiceOver necesita saber qué campo es aunque ya tenga
/// contenido. También comunica en texto si el campo es obligatorio u opcional.
struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    var hint: String?
    var isRequired: Bool = false
    var autocapitalization: TextInputAutocapitalization = .sentences
    var keyboardType: UIKeyboardType = .default
    var identifier: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Text(label)
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.inkMuted)

                Text(isRequired
                    ? String(localized: "Obligatorio")
                    : String(localized: "Opcional"))
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .opacity(0.75)
            }
            .accessibilityHidden(true)

            TextField("", text: $text)
                .font(AppFont.body)
                .textInputAutocapitalization(autocapitalization)
                .keyboardType(keyboardType)
                .accessibilityLabel(Text(accessibilityLabel))
                .accessibilityHint(Text(hint ?? ""))
                .accessibilityIdentifier(identifier ?? "")

            if let hint {
                Text(hint)
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private var accessibilityLabel: String {
        isRequired
            ? String(localized: "\(label), obligatorio")
            : String(localized: "\(label), opcional")
    }
}
