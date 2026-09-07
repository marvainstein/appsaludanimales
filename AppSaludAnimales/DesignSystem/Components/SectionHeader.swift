import SwiftUI

/// Encabezado de sección marcado como encabezado accesible, para que el rotor de
/// VoiceOver permita saltar de sección en sección en vez de recorrer todo el
/// contenido en orden.
struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(AppFont.sectionTitle)
                .foregroundStyle(Palette.ink)

            if let subtitle {
                Text(subtitle)
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Tarjeta de una línea del dashboard: ícono, título, detalle y estado.
struct DashboardItemCard: View {
    let item: DashboardItem
    var referenceDate: Date = .now

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            if !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: item.symbolName)
                    .font(.title3)
                    .foregroundStyle(Palette.accent)
                    .frame(width: Spacing.xl)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(item.title)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Palette.ink)

                if let detail = item.detail, !detail.isEmpty {
                    Text(detail)
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)
                }

                if let date = item.date {
                    Text(DateDescription.relative(date, from: referenceDate))
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.inkMuted)
                }

                if let badge = item.badge {
                    StatusChip(status: badge)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
    }
}

/// Estado vacío de una sección. Explica qué va a aparecer ahí, sin presentar la
/// ausencia de datos como algo que la persona hizo mal.
struct SectionEmptyState: View {
    let message: String

    var body: some View {
        Text(message)
            .font(AppFont.secondary)
            .foregroundStyle(Palette.inkMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Palette.surfaceMuted)
            )
    }
}
