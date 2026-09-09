import Charts
import SwiftUI

/// La evolución del peso.
///
/// El gráfico es una ayuda, no la información. La misma evolución está escrita
/// arriba en una frase y abajo en una lista de valores: quien no ve el dibujo
/// —o quien mira el teléfono apurado en una sala de espera— recibe exactamente
/// lo mismo.
struct WeightChartView: View {
    let companion: Companion

    private var trend: WeightTrend {
        WeightTrendBuilder.trend(for: companion)
    }

    var body: some View {
        List {
            if trend.points.isEmpty {
                Section {
                    EmptyStateIllustration(kind: .weight)
                        .listRowBackground(Color.clear)

                    SectionEmptyState(
                        message: String(localized: "Todavía no hay pesos registrados. Cuando cargues el primero, aparece acá.")
                    )
                }
            } else {
                summarySection
                chartSection
                valuesSection
            }
        }
        .navigationTitle(Text("Peso"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Resumen

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let latest = trend.latest {
                    Text(latest.formattedValue)
                        .font(AppFont.screenTitle)
                        .foregroundStyle(Palette.ink)

                    Text(DateDescription.relative(latest.date))
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)
                }

                if let change = WeightTrendBuilder.changeDescription(for: trend) {
                    Text(change)
                        .font(AppFont.body)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, Spacing.xs)
            .accessibilityElement(children: .combine)
        } header: {
            Text("Último peso")
        } footer: {
            Text("La app muestra cómo cambió, no si está bien o mal. Eso lo dice el veterinario.")
        }
    }

    // MARK: - Gráfico

    @ViewBuilder
    private var chartSection: some View {
        if trend.hasEnoughToDraw {
            Section {
                Chart(trend.points) { point in
                    LineMark(
                        x: .value(String(localized: "Fecha"), point.date),
                        y: .value(String(localized: "Peso"), point.value)
                    )
                    .foregroundStyle(Palette.accent)
                    .interpolationMethod(.monotone)

                    PointMark(
                        x: .value(String(localized: "Fecha"), point.date),
                        y: .value(String(localized: "Peso"), point.value)
                    )
                    .foregroundStyle(Palette.accent)
                }
                .chartYScale(domain: WeightTrendBuilder.valueRange(for: trend))
                .frame(height: 220)
                .padding(.vertical, Spacing.sm)
                // El dibujo no se recorre punto por punto: la misma evolución se
                // lee entera acá, y con todos los valores en la sección de abajo.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Gráfico de la evolución del peso"))
                .accessibilityValue(Text(WeightTrendBuilder.summary(for: trend)))
            }
        }
    }

    // MARK: - Valores

    private var valuesSection: some View {
        Section {
            ForEach(trend.points.reversed()) { point in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
                    Text(point.formattedValue)
                        .font(AppFont.cardTitle)
                        .foregroundStyle(Palette.ink)

                    Spacer(minLength: 0)

                    Text(DateDescription.absolute(point.date))
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)
                }
                .frame(minHeight: Spacing.minimumTapTarget)
                .accessibilityElement(children: .combine)
            }
        } header: {
            Text("Todos los pesos")
        } footer: {
            Text("Del más nuevo al más viejo. Para corregir uno, entrá desde el historial.")
        }
    }
}
