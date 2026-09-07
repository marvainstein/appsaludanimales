import SwiftData
import SwiftUI

/// Punto de entrada de la interfaz. Por ahora lista los compañeros registrados:
/// confirma que la persistencia funciona de punta a punta y es la semilla de la
/// pantalla real de compañeros.
struct RootView: View {
    var storageIsTemporary: Bool = false

    @Query(sort: \Companion.name) private var companions: [Companion]

    var body: some View {
        NavigationStack {
            Group {
                if companions.isEmpty {
                    emptyState
                } else {
                    companionList
                }
            }
            .navigationTitle(Text("Compañeros"))
            .background(Palette.background)
            .safeAreaInset(edge: .top) {
                if storageIsTemporary {
                    temporaryStorageNotice
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label {
                Text("Todavía no hay compañeros")
            } icon: {
                Image(systemName: "pawprint")
            }
        } description: {
            Text("Cuando agregues a tu compañero o compañera, su información va a vivir acá.")
        }
    }

    private var companionList: some View {
        List(companions) { companion in
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(companion.displayName)
                    .font(AppFont.cardTitle)

                Text(companionSubtitle(for: companion))
                    .font(AppFont.secondary)
                    .foregroundStyle(Palette.inkMuted)
            }
            .padding(.vertical, Spacing.xs)
            .accessibilityElement(children: .combine)
        }
        .listStyle(.insetGrouped)
    }

    private func companionSubtitle(for companion: Companion) -> String {
        guard let age = companion.age else {
            return companion.species.label
        }

        return "\(companion.species.label) · \(age.formatted)"
    }

    private var temporaryStorageNotice: some View {
        Text("Los datos de esta sesión no se están guardando. Podés seguir usando la app y volver a intentarlo más tarde.")
            .font(AppFont.caption)
            .foregroundStyle(StatusTone.attention.content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(StatusTone.attention.softBackground)
    }
}

#Preview("Sin compañeros") {
    RootView()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
