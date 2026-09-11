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
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(subtitle)
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
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

    /// Qué hacer cuando alguien toca la casilla de anotar. Sin esto la casilla
    /// no aparece.
    var onRecordDose: (() -> Void)?

    /// Qué dice la casilla: "Anotar toma" para una medicación, "Anotar sesión"
    /// para un tratamiento.
    var recordLabel: String = String(localized: "Anotar toma")

    /// Qué hacer cuando alguien toca la tarjeta para ver la ficha completa. Sin
    /// esto la tarjeta no es tocable, que es como se comporta en las secciones
    /// donde no hay nada más que ver.
    var onOpen: (() -> Void)?

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

            content
                .frame(maxWidth: .infinity, alignment: .leading)

            if let onRecordDose {
                doseButton(onRecordDose)
            }
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
    }

    /// El texto de la tarjeta. Si hay una ficha que abrir es un botón, y lleva
    /// la flecha que lo dice; si no, es texto y nada más.
    @ViewBuilder
    private var content: some View {
        if let onOpen {
            Button(action: onOpen) {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    texts

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.inkMuted)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(Text("Abre la ficha completa"))
        } else {
            texts
                .accessibilityElement(children: .combine)
        }
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(item.title)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail = item.detail, !detail.isEmpty {
                    Text(detail)
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
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

    /// Una casilla que dice lo que hace antes de que la toques.
    ///
    /// Es un botón propio y no la fila entera: quien toca para mirar no debería
    /// terminar anotando una toma que no dio. Y con el cuerpo de letra grande
    /// baja debajo del texto en vez de apretarlo contra el borde.
    private func doseButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: "checkmark.circle")
                    .font(.title2)

                Text(recordLabel)
                    .font(AppFont.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(Palette.accent)
            .frame(minWidth: Spacing.minimumTapTarget, minHeight: Spacing.minimumTapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(recordLabel): \(item.title)"))
        .accessibilityHint(Text("Se guarda con la hora de este momento"))
        .accessibilityIdentifier("dashboard.recordDose")
    }
}

/// Estado vacío de una sección. Explica qué va a aparecer ahí, sin presentar la
/// ausencia de datos como algo que la persona hizo mal.
struct SectionEmptyState: View {
    let message: String

    /// El fondo se puede cambiar porque la pantalla de quien cruzó el arcoíris
    /// tiene su propia paleta.
    var background: Color = Palette.surfaceMuted

    var body: some View {
        Text(message)
            .font(AppFont.secondary)
            .foregroundStyle(Palette.inkMuted)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(background)
            )
    }
}
