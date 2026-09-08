import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Adjuntar un estudio, una receta o cualquier documento.
///
/// Se puede traer desde las fotos o desde archivos: un análisis llega por correo
/// como PDF y una receta se saca con la cámara, y las dos cosas tienen que
/// entrar igual de fácil.
struct DocumentRecordView: View {
    let companion: Companion
    var onFinished: () -> Void = {}

    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var category = ""
    @State private var date = Date()
    @State private var accessibilityDescription = ""
    @State private var fileData: Data?
    @State private var fileName: String?
    @State private var contentTypeIdentifier: String?
    @State private var photoItem: PhotosPickerItem?
    @State private var isImportingFile = false
    @State private var errorMessage: String?

    private var canSave: Bool {
        fileData != nil && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section {
                if let summary = fileSummary {
                    Label {
                        Text(summary)
                    } icon: {
                        Image(systemName: "paperclip")
                    }
                    .foregroundStyle(Palette.ink)
                }

                PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                    Label {
                        Text(fileData == nil ? "Elegir una foto" : "Cambiar por una foto")
                    } icon: {
                        Image(systemName: "photo")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }

                Button {
                    isImportingFile = true
                } label: {
                    Label {
                        Text(fileData == nil ? "Elegir un archivo" : "Cambiar por un archivo")
                    } icon: {
                        Image(systemName: "doc")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
            } header: {
                Text("Documento")
            } footer: {
                Text("Podés adjuntar una foto o un archivo, por ejemplo un PDF de un análisis.")
            }

            Section {
                LabeledTextField(
                    label: String(localized: "Título"),
                    text: $title,
                    isRequired: true,
                    autocapitalization: .sentences
                )

                LabeledTextField(
                    label: String(localized: "Categoría"),
                    text: $category,
                    autocapitalization: .sentences
                )

                categorySuggestions

                DatePicker(selection: $date, displayedComponents: .date) {
                    Text("Fecha del documento")
                }
            } header: {
                Text("Datos")
            }

            Section {
                LabeledTextField(
                    label: String(localized: "Descripción del contenido"),
                    text: $accessibilityDescription,
                    hint: String(localized: "Se lee en voz alta para quien no puede ver el documento.")
                )
            } header: {
                Text("Accesibilidad")
            }

            PrimaryButtonSection(
                title: String(localized: "Guardar el documento"),
                hint: canSave ? nil : missingHint,
                isEnabled: canSave,
                action: save
            )
        }
        .navigationTitle(Text("Documento"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photoItem) { _, item in loadPhoto(item) }
        .fileImporter(
            isPresented: $isImportingFile,
            allowedContentTypes: [.pdf, .image, .plainText],
            allowsMultipleSelection: false
        ) { result in
            loadFile(result)
        }
        .alert(
            Text("No pudimos guardar"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("Entendido", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var categorySuggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(DocumentCategorySuggestions.all, id: \.self) { suggestion in
                    FilterChip(
                        title: suggestion,
                        symbolName: "tag",
                        isSelected: category == suggestion
                    ) {
                        category = category == suggestion ? "" : suggestion
                    }
                }
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    private var fileSummary: String? {
        guard let fileData else { return nil }

        let size = ByteCountFormatter.string(
            fromByteCount: Int64(fileData.count),
            countStyle: .file
        )

        guard let fileName else { return String(localized: "Foto elegida · \(size)") }
        return "\(fileName) · \(size)"
    }

    private var missingHint: String {
        fileData == nil
            ? String(localized: "Elegí una foto o un archivo para poder guardarlo")
            : String(localized: "Escribí un título para poder guardarlo")
    }

    // MARK: - Cargar el archivo

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                errorMessage = String(localized: "No pudimos usar esa imagen. Podés intentar con otra.")
                return
            }

            fileData = data
            fileName = nil
            contentTypeIdentifier = UTType.jpeg.identifier
            suggestDefaultsIfNeeded(from: nil)
        }
    }

    private func loadFile(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result, let url = urls.first else { return }

        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            errorMessage = String(localized: "No pudimos leer ese archivo. Podés intentar con otro.")
            return
        }

        fileData = data
        fileName = url.lastPathComponent
        contentTypeIdentifier = UTType(filenameExtension: url.pathExtension)?.identifier
        suggestDefaultsIfNeeded(from: url.deletingPathExtension().lastPathComponent)
    }

    /// Propone el nombre del archivo como título: casi siempre alcanza, y evita
    /// escribir lo mismo dos veces.
    private func suggestDefaultsIfNeeded(from suggestedTitle: String?) {
        guard title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if let suggestedTitle, !suggestedTitle.isEmpty {
            title = DocumentFileName.sanitize(suggestedTitle)
        }
    }

    private func save() {
        let document = HealthDocument(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: optional(category),
            date: date
        )
        document.fileData = fileData
        document.fileName = fileName
        document.contentTypeIdentifier = contentTypeIdentifier
        document.accessibilityDescription = optional(accessibilityDescription)
        companion.documents.append(document)

        do {
            try modelContext.save()
            onFinished()
        } catch {
            errorMessage = String(localized: "El documento no se guardó. Podés intentar de nuevo en un momento.")
        }
    }

    private func optional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
