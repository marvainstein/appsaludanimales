import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Crear un respaldo y restaurarlo.
///
/// Es la pantalla que uno espera no necesitar nunca, y la única que importa el
/// día que el teléfono se rompe.
struct BackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Companion.createdAt) private var companions: [Companion]

    @State private var backupURL: URL?
    @State private var isPreparing = false
    @State private var isImporting = false
    @State private var restoreSummary: BackupRestoreSummary?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Text("El respaldo es un archivo con toda la historia de salud de todos tus perros y gatos: los datos, los documentos adjuntos y las fotos. Guardalo donde quieras y volvé a cargarlo en cualquier teléfono.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Qué es")
            } footer: {
                Text("Ese archivo tiene información de salud. Guardalo en un lugar en el que confíes, igual que harías con los estudios en papel.")
            }

            Section {
                if let backupURL {
                    ShareLink(item: backupURL) {
                        Label {
                            Text("Compartir o guardar el respaldo")
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .frame(minHeight: Spacing.minimumTapTarget)
                    }
                    .accessibilityHint(Text("Abre las opciones del sistema para guardar el archivo"))
                }

                PrimaryButton(
                    title: isPreparing
                        ? String(localized: "Preparando el respaldo…")
                        : String(localized: "Crear un respaldo ahora"),
                    hint: companions.isEmpty
                        ? String(localized: "Todavía no hay nada para respaldar")
                        : nil,
                    isEnabled: !companions.isEmpty && !isPreparing,
                    identifier: "backup.create",
                    action: createBackup
                )
            } header: {
                Text("Crear")
            } footer: {
                Text(lastBackupFooter)
            }

            Section {
                Button {
                    isImporting = true
                } label: {
                    Label {
                        Text("Restaurar desde un archivo")
                    } icon: {
                        Image(systemName: "arrow.down.doc")
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
                .accessibilityIdentifier("backup.restore")
            } header: {
                Text("Restaurar")
            } footer: {
                Text("Restaurar agrega lo que falta y no borra ni reemplaza nada de lo que ya tenés. Podés restaurar el mismo archivo dos veces sin que se dupliquen los registros.")
            }
        }
        .navigationTitle(Text("Respaldo"))
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            restore(result)
        }
        .alert(
            Text("Listo"),
            isPresented: Binding(
                get: { restoreSummary != nil },
                set: { if !$0 { restoreSummary = nil } }
            )
        ) {
            Button("Entendido", role: .cancel) { restoreSummary = nil }
        } message: {
            Text(restoreSummary?.message ?? "")
        }
        .alert(
            Text("No pudimos hacerlo"),
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

    private var lastBackupFooter: String {
        backupURL == nil
            ? String(localized: "Conviene hacerlo cada tanto, y sobre todo antes de cambiar de teléfono.")
            : String(localized: "El respaldo está listo. Compartilo para guardarlo fuera del teléfono: si queda solo acá, no sirve de respaldo.")
    }

    // MARK: - Crear

    private func createBackup() {
        isPreparing = true
        backupURL = nil

        // Con muchos documentos adjuntos esto no es instantáneo, y bloquear la
        // pantalla mientras tanto haría parecer que la app se colgó.
        let snapshot = BackupService.archive(for: companions)

        Task {
            do {
                let data = try BackupService.encode(snapshot)
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent(BackupService.fileName())

                try data.write(to: url, options: .atomic)

                await MainActor.run {
                    backupURL = url
                    isPreparing = false
                    BackupPreferences.lastBackup = Date()
                    BackupPreferences.snoozedAt = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = String(localized: "No pudimos armar el respaldo. Podés intentar de nuevo en un momento.")
                    isPreparing = false
                }
            }
        }
    }

    // MARK: - Restaurar

    private func restore(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result, let url = urls.first else { return }

        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let archive = try BackupService.decode(data)
            restoreSummary = try BackupService.restore(archive, into: modelContext)
            ReminderSync.refresh(using: modelContext)
        } catch let error as BackupError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = String(localized: "No pudimos leer ese archivo. Fijate que sea el respaldo que bajaste de esta app.")
        }
    }
}
