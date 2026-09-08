import SwiftUI
import UIKit

/// Vista previa de un documento adjunto, con la opción de compartirlo.
///
/// Las imágenes se ven acá mismo; el resto se abre o se comparte con el sistema
/// nativo, que es lo que la persona ya sabe usar.
struct DocumentPreview: View {
    let document: HealthDocument
    let companionName: String

    @State private var shareURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let image = previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                    .accessibilityLabel(Text(imageDescription))
            } else if document.fileData != nil {
                Label {
                    Text(document.fileName ?? String(localized: "Archivo adjunto"))
                } icon: {
                    Image(systemName: "doc.text")
                }
                .font(AppFont.cardTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(Palette.surfaceMuted)
                )
            }

            if let shareURL {
                ShareLink(item: shareURL) {
                    Label {
                        Text("Compartir")
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
                .accessibilityHint(Text("Abre las opciones del sistema para enviar o guardar el documento"))
            }
        }
        .padding(.vertical, Spacing.xs)
        .onAppear(perform: prepareShareURL)
    }

    private var previewImage: UIImage? {
        guard DocumentFileStore.isImage(document), let data = document.fileData else { return nil }
        return UIImage(data: data)
    }

    private var imageDescription: String {
        if let description = document.accessibilityDescription, !description.isEmpty {
            return description
        }

        return String(localized: "Documento: \(document.title)")
    }

    private func prepareShareURL() {
        guard shareURL == nil else { return }
        shareURL = DocumentFileStore.temporaryURL(for: document, companionName: companionName)
    }
}
