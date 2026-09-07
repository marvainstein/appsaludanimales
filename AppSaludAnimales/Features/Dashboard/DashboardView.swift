import SwiftData
import SwiftUI

/// Pantalla principal: qué necesito saber hoy sobre mi compañero.
///
/// Cuatro secciones en orden de urgencia. Las que todavía no tienen nada
/// explican qué va a aparecer ahí, en vez de mostrarse vacías.
struct DashboardView: View {
    let companion: Companion
    var companions: [Companion] = []
    var onSelectCompanion: (Companion) -> Void = { _ in }

    @State private var isAddingCompanion = false
    @State private var isRecording = false
    @State private var referenceDate = Date()

    private var snapshot: DashboardSnapshot {
        DashboardBuilder.snapshot(for: companion, on: referenceDate)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                companionHeader

                section(
                    title: String(localized: "Hoy"),
                    items: snapshot.today,
                    emptyMessage: String(localized: "No hay nada anotado para hoy.")
                )

                section(
                    title: String(localized: "Próximamente"),
                    subtitle: String(localized: "Los próximos 30 días"),
                    items: snapshot.upcoming,
                    emptyMessage: String(localized: "Cuando anotes un turno o una próxima vacuna, aparece acá.")
                )

                section(
                    title: String(localized: "Estado actual"),
                    items: snapshot.currentStatus,
                    emptyMessage: String(localized: "Acá vas a ver las medicaciones y los tratamientos en curso.")
                )

                section(
                    title: String(localized: "Actividad reciente"),
                    items: snapshot.recentActivity,
                    emptyMessage: String(localized: "Todavía no hay nada registrado. Lo que anotes va a quedar guardado acá.")
                )
            }
            .padding(Spacing.lg)
        }
        .background(Palette.background)
        .navigationTitle(Text("Hoy"))
        .safeAreaInset(edge: .bottom) { recordBar }
        .toolbar { toolbarContent }
        .sheet(isPresented: $isRecording) {
            QuickRecordSheet(companion: companion)
        }
        .sheet(isPresented: $isAddingCompanion) {
            NavigationStack {
                CompanionFormView(mode: .create) { newCompanion in
                    onSelectCompanion(newCompanion)
                }
            }
        }
        .onAppear { referenceDate = Date() }
    }

    // MARK: - Encabezado

    private var companionHeader: some View {
        NavigationLink {
            CompanionProfileView(companion: companion)
        } label: {
            HStack(spacing: Spacing.lg) {
                CompanionAvatar(companion: companion, size: 72)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(companion.displayName)
                        .font(AppFont.screenTitle)
                        .foregroundStyle(Palette.ink)

                    Text(subtitle)
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Palette.surface)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(companion.displayName). \(subtitle)"))
        .accessibilityHint(Text("Abre el perfil"))
        .accessibilityAddTraits(.isButton)
    }

    private var subtitle: String {
        guard let age = companion.age else {
            return companion.species.label
        }

        return "\(companion.species.label) · \(age.formatted)"
    }

    /// La acción central vive siempre a la vista, no escondida en un menú: es lo
    /// que la persona más va a hacer, muchas veces con una sola mano.
    private var recordBar: some View {
        PrimaryButton(
            title: String(localized: "Registrar"),
            symbolName: "plus",
            hint: String(localized: "Anotar una medicación, un síntoma, el peso, una vacuna o una nota")
        ) {
            isRecording = true
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(.bar)
    }

    // MARK: - Secciones

    private func section(
        title: String,
        subtitle: String? = nil,
        items: [DashboardItem],
        emptyMessage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: title, subtitle: subtitle)

            if items.isEmpty {
                SectionEmptyState(message: emptyMessage)
            } else {
                ForEach(items) { item in
                    DashboardItemCard(item: item, referenceDate: referenceDate)
                }
            }
        }
    }

    // MARK: - Barra de herramientas

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if companions.count > 1 {
                    Section {
                        ForEach(companions) { option in
                            Button {
                                onSelectCompanion(option)
                            } label: {
                                Label {
                                    Text(option.displayName)
                                } icon: {
                                    Image(systemName: option.id == companion.id
                                        ? "checkmark"
                                        : option.species.symbolName)
                                }
                            }
                        }
                    } header: {
                        Text("Cambiar de compañero")
                    }
                }

                Button {
                    isAddingCompanion = true
                } label: {
                    Label {
                        Text("Agregar compañero")
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
            } label: {
                Label {
                    Text("Compañeros")
                } icon: {
                    Image(systemName: "pawprint.circle")
                }
            }
            .accessibilityLabel(Text("Compañeros"))
            .accessibilityHint(Text("Cambiar de compañero o agregar uno nuevo"))
        }
    }
}
