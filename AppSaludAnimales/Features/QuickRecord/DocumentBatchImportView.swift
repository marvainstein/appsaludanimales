import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Traer varios documentos de una y repasarlos antes de guardar.
///
/// El archivo de salud de años no se carga de a un documento por vez. Pero
/// tampoco alcanza con tragarse treinta archivos y listo: sin título ni fecha
/// serían treinta registros imposibles de encontrar. Por eso el flujo son dos
/// pasos, elegir y repasar, con la app proponiendo todo lo que puede deducir
/// sola del nombre del archivo.
struct DocumentBatchImportView: View {
    let companion: Companion
    var onFinished: () -> Void = {}

    @Environment(\.modelContext) private var modelContext

    @State private var drafts: [DocumentImportDraft] = []
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var isImportingFiles = false
    @State private var errorMessage: String?

    private var readyCount: Int {
        drafts.filter(\.isReady).count
    }

    var body: some View {
        Form {
            pickerSection

            ForEach($drafts) { $draft in
                draftSection(for: $draft)
            }

            if !drafts.isEmpty {
                PrimaryButtonSection(
                    title: DocumentBatchImport.saveButtonTitle(for: drafts),
                    hint: DocumentBatchImport.pendingTitleMessage(for: drafts),
                    isEnabled: readyCount == drafts.count,
                    identifier: "batchImport.save",
                    action: save
                )
            }
        }
        .navigationTitle(Text("Varios documentos"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photoItems) { _, items in loadPhotos(items) }
        .fileImporter(
            isPresented: $isImportingFiles,
            allowedContentTypes: DocumentFileStore.importableTypes,
            allowsMultipleSelection: true
        ) { result in
            loadFiles(result)
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

    // MARK: - Elegir

    private var pickerSection: some View {
        Section {
            Button {
                isImportingFiles = true
            } label: {
                Label {
                    Text("Elegir archivos")
                } icon: {
                    Image(systemName: "doc.on.doc")
                }
                .frame(minHeight: Spacing.minimumTapTarget)
            }
            .accessibilityIdentifier("batchImport.files")

            PhotosPicker(
                selection: $photoItems,
                maxSelectionCount: DocumentBatchImport.maximumFiles,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label {
                    Text("Elegir fotos")
                } icon: {
                    Image(systemName: "photo.on.rectangle")
                }
                .frame(minHeight: Spacing.minimumTapTarget)
            }
        } header: {
            Text("Qué traer")
        } footer: {
            Text(drafts.isEmpty
                ? "Podés elegir varios a la vez. Si tenés los estudios guardados en otra aplicación, aparece como una ubicación más dentro de Archivos."
                : "\(drafts.count) elegidos. Podés agregar más o quitar los que no van.")
        }
    }

    // MARK: - Repasar

    private func draftSection(for draft: Binding<DocumentImportDraft>) -> some View {
        Section {
            LabeledTextField(
                label: String(localized: "Título"),
                text: draft.title,
                isRequired: true,
                autocapitalization: .sentences
            )

            LabeledTextField(
                label: String(localized: "Categoría"),
                text: draft.category,
                autocapitalization: .sentences
            )

            DatePicker(selection: draft.date, displayedComponents: .date) {
                Text("Fecha del documento")
            }

            Button(role: .destructive) {
                remove(draft.wrappedValue.id)
            } label: {
                Label {
                    Text("Quitar de la lista")
                } icon: {
                    Image(systemName: "minus.circle")
                }
                .frame(minHeight: Spacing.minimumTapTarget)
            }
            .accessibilityHint(Text("Este documento no se guarda. El archivo original no se toca."))
        } header: {
            Text(draft.wrappedValue.fileName ?? String(localized: "Foto elegida"))
        }
    }

    // MARK: - Cargar

    private func loadFiles(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result else { return }

        var unreadable = 0
        var tooLarge = 0

        for url in urls.prefix(remainingCapacity) {
            let needsAccess = url.startAccessingSecurityScopedResource()
            defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

            guard let data = try? Data(contentsOf: url) else {
                unreadable += 1
                continue
            }

            guard DocumentFileStore.isWithinSizeLimit(data) else {
                tooLarge += 1
                continue
            }

            drafts.append(
                DocumentBatchImport.draft(
                    fileName: url.lastPathComponent,
                    data: data,
                    contentTypeIdentifier: UTType(filenameExtension: url.pathExtension)?.identifier
                )
            )
        }

        reportIfIncomplete(chosen: urls.count, unreadable: unreadable, tooLarge: tooLarge)
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        Task {
            var unreadable = 0
            var tooLarge = 0
            let capacity = remainingCapacity

            for item in items.prefix(capacity) {
                guard let data = try? await item.loadTransferable(type: Data.self) else {
                    unreadable += 1
                    continue
                }

                guard DocumentFileStore.isWithinSizeLimit(data) else {
                    tooLarge += 1
                    continue
                }

                drafts.append(
                    DocumentBatchImport.draft(
                        fileName: nil,
                        data: data,
                        contentTypeIdentifier: UTType.jpeg.identifier
                    )
                )
            }

            reportIfIncomplete(chosen: items.count, unreadable: unreadable, tooLarge: tooLarge)
            photoItems = []
        }
    }

    private var remainingCapacity: Int {
        max(0, DocumentBatchImport.maximumFiles - drafts.count)
    }

    /// Cuando algo no entró, se dice cuántos y por qué. Que falten documentos sin
    /// aviso es peor que no poder traerlos.
    private func reportIfIncomplete(chosen: Int, unreadable: Int, tooLarge: Int) {
        let overflow = max(0, chosen - remainingCapacity - unreadable - tooLarge)

        var reasons: [String] = []

        if unreadable > 0 {
            reasons.append(String(localized: "\(unreadable) no se pudieron leer"))
        }

        if tooLarge > 0 {
            reasons.append(String(localized: "\(tooLarge) pesan más de \(DocumentFileStore.sizeLimitDescription)"))
        }

        if overflow > 0 {
            reasons.append(String(localized: "\(overflow) quedaron afuera porque se pueden traer hasta \(DocumentBatchImport.maximumFiles) por vez"))
        }

        guard !reasons.isEmpty else { return }

        errorMessage = String(localized: "\(reasons.formatted(.list(type: .and))). Los demás sí entraron.")
    }

    // MARK: - Guardar

    private func remove(_ id: UUID) {
        drafts.removeAll { $0.id == id }
    }

    private func save() {
        for draft in drafts where draft.isReady {
            let document = HealthDocument(date: draft.date)
            document.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
            document.category = optional(draft.category)
            document.fileData = draft.data
            document.fileName = draft.fileName
            document.contentTypeIdentifier = draft.contentTypeIdentifier
            companion.documents.append(document)
        }

        do {
            try modelContext.save()
            onFinished()
        } catch {
            errorMessage = String(localized: "Los documentos no se guardaron. Podés intentar de nuevo en un momento.")
        }
    }

    private func optional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
