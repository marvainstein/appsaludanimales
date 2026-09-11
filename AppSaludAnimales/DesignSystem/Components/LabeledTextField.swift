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

    @FocusState private var isFocused: Bool

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
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit { isFocused = false }
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
        // Los márgenes de la fila, tomados a mano.
        //
        // El renglón de abajo de un campo se lee como la línea sobre la que uno
        // escribe, y el texto quedaba flotando a media altura entre su etiqueta
        // y esa línea. Dos intentos de arreglarlo con `padding` no sirvieron, y
        // el motivo es que ese espacio no lo ponía el padding: cada fila de un
        // formulario trae unos once puntos de relleno propio abajo, y el padding
        // se le sumaba en vez de reemplazarlo.
        //
        // Los márgenes laterales quedan en veinte, que es el valor del sistema:
        // si se cambiaran, este campo se desalinearía de los interruptores y los
        // selectores de fecha, que siguen usando el suyo.
        .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 4, trailing: 20))
        // Una salida del teclado que no dependa de tocar en el lugar correcto de
        // la pantalla.
        //
        // Tocando afuera el teclado se cerraba, así que a la vista parecía que
        // no faltaba nada. Con VoiceOver no hay "afuera": después de escribir el
        // nombre no había forma de volver al formulario, y el botón de guardar
        // quedaba tapado por el teclado. El teclado numérico del peso es peor
        // todavía, porque ni siquiera tiene tecla de retorno.
        //
        // El botón aparece solo para el campo que está escribiendo: si cada
        // campo pusiera el suyo, se apilarían varios sobre el mismo teclado.
        .toolbar {
            if isFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button {
                        isFocused = false
                    } label: {
                        Text("Listo")
                    }
                    .accessibilityHint(Text("Cierra el teclado y vuelve al formulario"))
                    .accessibilityIdentifier("keyboard.done")
                }
            }
        }
    }

    private var accessibilityLabel: String {
        isRequired
            ? String(localized: "\(label), obligatorio")
            : String(localized: "\(label), opcional")
    }
}
