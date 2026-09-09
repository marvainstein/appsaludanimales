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

                    Text("¿Qué vas a encontrar?")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    promises

                    NavigationLink {
                        CompanionFormView(mode: .onboarding)
                    } label: {
                        Text("Empezar")
                            .font(AppFont.cardTitle)
                            .frame(maxWidth: .infinity, minHeight: Spacing.minimumTapTarget)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint(Text("Abre el formulario para agregar a tu perro o tu gato"))
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

            Text("¡Buenas!")
                .font(AppFont.screenTitle)
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)

            Text("Este es el lugar donde vas a poder anotar y encontrar de manera sencilla el historial de salud de tu perro o de tu gato.")
                .font(AppFont.body)
                .foregroundStyle(Palette.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var promises: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            promise(
                symbol: "clock",
                title: String(localized: "Anotar toma segundos"),
                detail: String(localized: "Una medicación, un síntoma, un peso o un estudio, sin recorrer un laberinto de archivos.")
            )
            promise(
                symbol: "calendar",
                title: String(localized: "Qué viene después"),
                detail: String(localized: "Turnos, vacunas y controles, siempre a la vista.")
            )
            promise(
                symbol: "heart.text.square",
                title: String(localized: "Todo junto para el veterinario"),
                detail: String(localized: "La información ordenada cuando hace falta contarla y directa para compartirla con el profesional.")
            )
            // La única pantalla donde alguien lee esta promesa es esta. Después
            // no vuelve a pasar por acá, y es de las cosas que más pesan al
            // decidir si se confía o no una historia clínica a una app.
            promise(
                symbol: "lock",
                title: String(localized: "Todo se guarda en tu teléfono"),
                detail: String(localized: "La información no se sube a internet. Si querés compartir algo, lo elegís vos.")
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
