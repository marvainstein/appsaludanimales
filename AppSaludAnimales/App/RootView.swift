import SwiftData
import SwiftUI

/// Decide qué ve la persona al abrir: la bienvenida mientras no haya ningún
/// compañero registrado, y el dashboard apenas exista el primero.
///
/// No hay una marca de "ya completó la bienvenida": el estado se deduce de los
/// datos, así no hay dos fuentes de verdad que puedan contradecirse.
struct RootView: View {
    var storageIsTemporary: Bool = false

    @Query(sort: \Companion.createdAt) private var companions: [Companion]
    @State private var selectedCompanionID: UUID?

    /// Al abrir se muestra a alguien que esté. Abrir la app y encontrarse de
    /// frente con quien ya no está no es una decisión que le corresponda tomar
    /// al teléfono: se entra a su perfil cuando se quiere entrar.
    private var selectedCompanion: Companion? {
        if let chosen = companions.first(where: { $0.id == selectedCompanionID }) {
            return chosen
        }

        return companions.first(where: \.isPresent) ?? companions.first
    }

    var body: some View {
        Group {
            if let companion = selectedCompanion {
                NavigationStack {
                    DashboardView(
                        companion: companion,
                        companions: companions,
                        onSelectCompanion: { selectedCompanionID = $0.id }
                    )
                }
            } else {
                OnboardingView()
            }
        }
        .safeAreaInset(edge: .top) {
            if storageIsTemporary {
                temporaryStorageNotice
            }
        }
    }

    private var temporaryStorageNotice: some View {
        Text("Los datos de esta sesión no se están guardando. Podés seguir usando la app y volver a intentarlo más tarde.")
            .font(AppFont.caption)
            .foregroundStyle(StatusTone.attention.content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(StatusTone.attention.softBackground)
            .accessibilityAddTraits(.isStaticText)
    }
}

#Preview("Bienvenida") {
    RootView()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
