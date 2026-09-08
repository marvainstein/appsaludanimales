import SwiftUI

/// Generar un resumen en PDF para llevarle al veterinario.
///
/// La persona elige el período y qué incluir: lo que se comparte no siempre es
/// todo, y esa decisión es suya.
struct ExportReportView: View {
    let companion: Companion

    @State private var period: ReportPeriod = .month
    @State private var selectedSections: Set<ReportSectionKind> = Set(
        ReportSectionKind.allCases.filter(\.isOnByDefault)
    )
    @State private var exportedFile: ExportedFile?
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private struct ExportedFile: Identifiable {
        let id = UUID()
        let url: URL
    }

    private var report: HealthReport {
        HealthReportBuilder.report(
            for: companion,
            period: period,
            sections: selectedSections
        )
    }

    var body: some View {
        Form {
            Section {
                Picker(selection: $period) {
                    ForEach(ReportPeriod.allCases) { option in
                        Text(option.label).tag(option)
                    }
                } label: {
                    Text("Período")
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(Text("Período del resumen"))
            } header: {
                Text("Período")
            } footer: {
                Text(period.description)
            }

            Section {
                ForEach(ReportSectionKind.allCases) { kind in
                    Toggle(isOn: binding(for: kind)) {
                        Text(kind.label)
                    }
                }
            } header: {
                Text("Qué incluir")
            } footer: {
                Text("Las secciones sin información no aparecen en el PDF, aunque estén marcadas.")
            }

            Section {
                if report.sections.isEmpty {
                    Text("Con lo que elegiste no hay nada para incluir todavía. Probá con otro período o marcá más secciones.")
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)
                } else {
                    ForEach(report.sections, id: \.title) { section in
                        HStack {
                            Text(section.title)
                            Spacer(minLength: Spacing.md)
                            Text(section.lines.count.formatted())
                                .foregroundStyle(Palette.inkMuted)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Text("\(section.title): \(section.lines.count) líneas"))
                    }
                }
            } header: {
                Text("Vista previa")
            }

            PrimaryButtonSection(
                title: String(localized: "Generar el PDF"),
                hint: report.sections.isEmpty
                    ? String(localized: "Elegí al menos una sección con información")
                    : nil,
                isEnabled: !report.sections.isEmpty && !isGenerating,
                action: generate
            )
        }
        .navigationTitle(Text("Resumen en PDF"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $exportedFile) { file in
            ShareSheet(url: file.url)
        }
        .alert(
            Text("No pudimos generar el PDF"),
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

    private func binding(for kind: ReportSectionKind) -> Binding<Bool> {
        Binding(
            get: { selectedSections.contains(kind) },
            set: { isOn in
                if isOn {
                    selectedSections.insert(kind)
                } else {
                    selectedSections.remove(kind)
                }
            }
        )
    }

    private func generate() {
        isGenerating = true
        defer { isGenerating = false }

        let data = PDFReportRenderer.render(report)
        let fileName = DocumentFileName.make(
            companionName: companion.displayName,
            title: String(localized: "Resumen de salud"),
            originalFileName: nil,
            defaultExtension: "pdf"
        )
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: url, options: .atomic)
            exportedFile = ExportedFile(url: url)
        } catch {
            errorMessage = String(localized: "El archivo no se pudo crear. Podés intentar de nuevo en un momento.")
        }
    }
}

/// Compartir con el mecanismo del sistema, que es el que la persona ya conoce.
private struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
