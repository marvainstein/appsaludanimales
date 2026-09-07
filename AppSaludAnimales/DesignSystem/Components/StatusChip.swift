import SwiftUI

/// Indicador de estado: texto, ícono y color, siempre los tres.
///
/// El color nunca viaja solo. Con Dynamic Type grande el ícono y el texto se
/// apilan en vertical en lugar de recortarse.
struct StatusChip: View {
    let status: any StatusPresentable

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    content
                }
            } else {
                HStack(spacing: Spacing.xs) {
                    content
                }
            }
        }
        .font(AppFont.chip)
        .foregroundStyle(status.tone.content)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                .fill(status.tone.softBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(status.label))
    }

    @ViewBuilder
    private var content: some View {
        Image(systemName: status.symbolName)
            .accessibilityHidden(true)
        Text(status.label)
    }
}

#Preview("Estados") {
    VStack(alignment: .leading, spacing: Spacing.md) {
        ForEach(ActivityStatus.allCases, id: \.self) { status in
            StatusChip(status: status)
        }
        ForEach(EpisodeStatus.allCases, id: \.self) { status in
            StatusChip(status: status)
        }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Palette.background)
}
