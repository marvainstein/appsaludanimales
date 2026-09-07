import SwiftData
import SwiftUI

/// Todo lo que pasó, de lo más nuevo a lo más viejo, agrupado por mes.
struct HistoryView: View {
    let companion: Companion

    @State private var selectedCategories: Set<HealthCategory> = []

    private var availableCategories: [HealthCategory] {
        HistoryBuilder.availableCategories(for: companion)
    }

    private var sections: [HistorySection] {
        HistoryBuilder.sections(for: companion, categories: selectedCategories)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if !availableCategories.isEmpty {
                    filters
                }

                if sections.isEmpty {
                    SectionEmptyState(message: emptyMessage)
                } else {
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            SectionHeader(title: section.title)

                            ForEach(section.entries) { entry in
                                NavigationLink {
                                    HealthRecordDetailView(companion: companion, entry: entry)
                                } label: {
                                    HistoryEntryCard(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .background(Palette.background)
        .navigationTitle(Text("Historial"))
    }

    private var emptyMessage: String {
        selectedCategories.isEmpty
            ? String(localized: "Todavía no hay nada registrado. Lo que anotes va a aparecer acá, ordenado por fecha.")
            : String(localized: "No hay nada registrado en lo que estás filtrando.")
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Filtrar")
                .font(AppFont.caption)
                .foregroundStyle(Palette.inkMuted)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    FilterChip(
                        title: String(localized: "Todo"),
                        symbolName: "square.grid.2x2",
                        isSelected: selectedCategories.isEmpty
                    ) {
                        selectedCategories = []
                    }

                    ForEach(availableCategories, id: \.self) { category in
                        FilterChip(
                            title: category.label,
                            symbolName: category.symbolName,
                            isSelected: selectedCategories.contains(category)
                        ) {
                            toggle(category)
                        }
                    }
                }
                .padding(.vertical, Spacing.xs)
            }
        }
    }

    private func toggle(_ category: HealthCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}

/// Filtro de categoría. Lo elegido se distingue por el tilde y por el texto de
/// estado que lee VoiceOver, no solo por el fondo.
struct FilterChip: View {
    let title: String
    let symbolName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: isSelected ? "checkmark" : symbolName)
                    .accessibilityHidden(true)

                Text(title)
            }
            .font(AppFont.chip)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(minHeight: Spacing.minimumTapTarget)
            .foregroundStyle(isSelected ? Palette.onAccentSoft : Palette.inkMuted)
            .background(
                Capsule().fill(isSelected ? Palette.accentSoft : Palette.surfaceMuted)
            )
        }
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(isSelected
            ? String(localized: "Filtrando")
            : String(localized: "Sin filtrar")))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct HistoryEntryCard: View {
    let entry: HistoryEntry

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            if !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: entry.category.symbolName)
                    .font(.title3)
                    .foregroundStyle(Palette.accent)
                    .frame(width: Spacing.xl)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(entry.category.label)
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.inkMuted)

                Text(entry.title)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Palette.ink)

                if let detail = entry.detail, !detail.isEmpty {
                    Text(detail)
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)
                }

                Text(DateDescription.absolute(entry.date))
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.inkMuted)

                if let badge = entry.badge {
                    StatusChip(status: badge)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Palette.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}
