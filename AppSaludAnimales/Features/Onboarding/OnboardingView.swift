import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Bienvenida y primer alta.
///
/// Dos pantallas y cuatro datos. Todo lo demás se completa después: pedir todo
/// junto al principio es la forma más rápida de que alguien abandone antes de
/// llegar a usar la app.
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isRestoring = false
    @State private var restoreFailed: String?

    var body: some View {
        NavigationStack {
            // El contenido va centrado a lo alto, con márgenes parecidos arriba
            // y abajo. Pegado al techo dejaba un vacío grande debajo del botón.
            // Con el texto grande crece hacia abajo y la pantalla scrollea, así
            // que centrar no le quita nada a nadie.
            GeometryReader { proxy in
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

                    restoreOffer
                }
                    .padding(Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: proxy.size.height, alignment: .center)
                }
                .background(Palette.background)
            }
            .fileImporter(
                isPresented: $isRestoring,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                if case let .failed(message) = RestoreFromFile.load(result, into: modelContext) {
                    restoreFailed = message
                }
            }
            .alert(
                Text("No pudimos leerlo"),
                isPresented: Binding(
                    get: { restoreFailed != nil },
                    set: { if !$0 { restoreFailed = nil } }
                )
            ) {
                Button("Entendido", role: .cancel) { restoreFailed = nil }
            } message: {
                Text(restoreFailed ?? "")
            }
        }
    }

    /// Para quien ya usaba la app y cambió de teléfono.
    ///
    /// Sin esto había que inventar un animal para poder recuperar los propios, y
    /// esa persona terminaba con un compañero fantasma al lado de los suyos. Va
    /// abajo y en tono menor porque no es lo que hace la mayoría: quien recién
    /// empieza no tiene ningún archivo.
    private var restoreOffer: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button {
                isRestoring = true
            } label: {
                Text("¿Ya usabas Estela? Restaurá tu respaldo")
                    .font(AppFont.secondary)
                    .foregroundStyle(Palette.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: Spacing.minimumTapTarget, alignment: .center)
            }
            .accessibilityHint(Text("Abre tus archivos para elegir el respaldo"))
            .accessibilityIdentifier("onboarding.restore")

            Text("Recuperás todos tus animales con su historia, sin tener que cargar nada de nuevo.")
                .font(AppFont.caption)
                .foregroundStyle(Palette.inkMuted)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)
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
