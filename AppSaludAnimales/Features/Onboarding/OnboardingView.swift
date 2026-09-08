import SwiftUI

/// Bienvenida y primer alta.
///
/// Dos pantallas y cuatro datos. Todo lo demás se completa después: pedir todo
/// junto al principio es la forma más rápida de que alguien abandone antes de
/// llegar a usar la app.
struct OnboardingView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    promises

                    NavigationLink {
                        CompanionFormView(mode: .onboarding)
                    } label: {
                        Text("Empezar")
                            .font(AppFont.cardTitle)
                            .frame(maxWidth: .infinity, minHeight: Spacing.minimumTapTarget)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint(Text("Abre el formulario para agregar a tu compañero o compañera"))
                    .accessibilityIdentifier("onboarding.start")
                }
                .padding(Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Palette.background)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Image(systemName: "pawprint")
                .font(AppFont.heroSymbol)
                .foregroundStyle(Palette.accent)
                .accessibilityHidden(true)

            Text("Hola")
                .font(AppFont.screenTitle)
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)

            Text("Este es el lugar donde va a vivir la historia de salud de tu compañero o compañera.")
                .font(AppFont.body)
                .foregroundStyle(Palette.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var promises: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            promise(
                symbol: "clock",
                title: String(localized: "Registrar toma segundos"),
                detail: String(localized: "Una medicación, un síntoma o un peso, sin recorrer pantallas.")
            )
            promise(
                symbol: "calendar",
                title: String(localized: "Qué viene después"),
                detail: String(localized: "Turnos, vacunas y controles, siempre a la vista.")
            )
            promise(
                symbol: "heart.text.square",
                title: String(localized: "Todo junto para el veterinario"),
                detail: String(localized: "La información ordenada cuando hace falta contarla.")
            )
        }
    }

    private func promise(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Palette.accent)
                .frame(width: Spacing.xl)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(AppFont.secondary)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Bienvenida") {
    OnboardingView()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
