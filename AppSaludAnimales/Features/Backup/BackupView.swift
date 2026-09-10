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
    @State private var syncIsOn = CloudSyncPreferences.isEnabled
    @State private var syncBlocked: CloudSyncAvailability?

    var body: some View {
        List {
            Section {
                Text("Hay dos maneras de que la historia de salud de tus perros y gatos no se pierda si el teléfono se rompe o se pierde. Una la hacés vos cuando querés; la otra se hace sola.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Que no se pierda")
            }

            automaticCopySection

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
                Text("Un archivo que guardás vos")
            } footer: {
                Text("\(lastBackupFooter) El archivo tiene toda la información, los documentos y las fotos. Guardalo en un lugar en el que confíes, igual que harías con los estudios en papel.")
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
        .alert(
            Text(blockedTitle),
            isPresented: Binding(
                get: { syncBlocked != nil },
                set: { if !$0 { syncBlocked = nil } }
            )
        ) {
            Button("Entendido", role: .cancel) { syncBlocked = nil }
        } message: {
            Text(blockedExplanation)
        }
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


    // MARK: - Que se guarde solo

    /// La copia automática, contada por lo que resuelve y no por cómo funciona.
    ///
    /// En ningún texto aparece la palabra "sincronizar": nadie quiere
    /// sincronizar, la gente quiere no perder las cosas. Y "un respaldo que se
    /// hace solo" es, además, literalmente lo que es.
    ///
    /// Vive acá y no en el tablero a propósito. La app no pide nada antes de
    /// que la persona haya visto para qué sirve, y a esta pantalla se llega
    /// cuando ya hay algo que perder: buscándola, o desde el aviso de respaldo,
    /// que aparece recién cuando hay información cargada.
    @ViewBuilder
    private var automaticCopySection: some View {
        Section {
            if syncIsOn {
                Label {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Está activado")
                            .font(AppFont.cardTitle)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Tu información se guarda sola en tu iCloud.")
                            .font(AppFont.secondary)
                            .foregroundStyle(Palette.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Palette.accent)
                }
                .padding(.vertical, Spacing.xs)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Está activado. Tu información se guarda sola en tu iCloud."))
            } else {
                Text("Se guarda en tu iCloud sin que tengas que acordarte de nada. Si perdés el teléfono, la información está ahí. No hace falta crear ninguna cuenta: se usa la de iCloud que ya tenés.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)

                PrimaryButton(
                    title: String(localized: "Que se guarde solo"),
                    identifier: "backup.enableAutomatic",
                    action: enableAutomaticCopy
                )
            }
        } header: {
            Text("Que se guarde solo")
        } footer: {
            Text(syncIsOn
                ? "La copia es tuya y vive en tu cuenta de iCloud. No tenemos servidores ni forma de ver lo que guardás."
                : "Podés activarlo ahora o cuando quieras: esta pantalla está siempre acá.")
        }
    }

    private var blockedTitle: String {
        syncBlocked.flatMap(\.titulo) ?? ""
    }

    private var blockedExplanation: String {
        syncBlocked.flatMap(\.explicacion) ?? ""
    }

    private func enableAutomaticCopy() {
        let disponibilidad = CloudSyncAvailability.current()

        guard disponibilidad == .disponible else {
            syncBlocked = disponibilidad
            return
        }

        CloudSyncPreferences.isEnabled = true
        syncIsOn = true
    }

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
