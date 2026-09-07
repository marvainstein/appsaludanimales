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
        .overlay(
            Circle().strokeBorder(Palette.separator, lineWidth: 1)
        )
    }

    private var photoDescription: String {
        if let description = companion.photoAccessibilityDescription, !description.isEmpty {
            return description
        }

        return String(localized: "Foto de \(companion.displayName)")
    }
}
