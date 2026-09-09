import SwiftUI
import UIKit

/// Foto del compañero, o una silueta discreta mientras no haya foto.
///
/// La descripción accesible es la que escribió la persona ("Foto de Luli, galga
/// negra y blanca"); si no hay ninguna, se construye una con el nombre. Sin foto,
/// la silueta es decorativa y las tecnologías asistivas la ignoran.
struct CompanionAvatar: View {
    let companion: Companion
    var size: CGFloat = 64

    @ScaledMetric private var scale: CGFloat = 1

    private var scaledSize: CGFloat { size * scale }

    var body: some View {
        Group {
            if let photoData = companion.photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel(Text(photoDescription))
            } else {
                Image(systemName: companion.species.symbolName)
                    .font(.system(size: scaledSize * 0.42))
                    .foregroundStyle(Palette.onAccentSoft)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.accentSoft)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: scaledSize, height: scaledSize)
        .clipShape(Circle())
        .overlay(border)
    }

    /// Un aro de colores suaves para quien ya no está.
    ///
    /// El color nunca cuenta la historia solo: el perfil lo dice con todas las
    /// letras y VoiceOver también. El aro es para reconocerlo de un vistazo, no
    /// para enterarse por él.
    @ViewBuilder
    private var border: some View {
        if companion.isPresent {
            Circle().strokeBorder(Palette.separator, lineWidth: 1)
        } else {
            Circle().strokeBorder(
                AngularGradient(
                    colors: [
                        Color(red: 0.91, green: 0.62, blue: 0.55),
                        Color(red: 0.93, green: 0.80, blue: 0.53),
                        Color(red: 0.72, green: 0.83, blue: 0.66),
                        Color(red: 0.60, green: 0.76, blue: 0.84),
                        Color(red: 0.76, green: 0.68, blue: 0.85),
                        Color(red: 0.91, green: 0.62, blue: 0.55)
                    ],
                    center: .center
                ),
                lineWidth: max(3, scaledSize * 0.05)
            )
        }
    }

    private var photoDescription: String {
        let base: String

        if let description = companion.photoAccessibilityDescription, !description.isEmpty {
            base = description
        } else {
            base = String(localized: "Foto de \(companion.displayName)")
        }

        guard !companion.isPresent else { return base }

        // Lo que dice el aro de colores, dicho también en palabras.
        return String(localized: "\(base). Cruzó el arcoíris.")
    }
}
