import SwiftData
import SwiftUI

/// Marcar que un compañero ya no está.
///
/// La pantalla dice qué va a pasar y qué no, porque el miedo razonable en este
/// momento es perder lo que se registró durante años. No se pierde nada.
struct FarewellSheet: View {
    let companion: Companion

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var saveFailed = false
    @State private var isSaved = false

    var body: some View {
        NavigationStack {
            if isSaved {
                farewellMessage
            } else {
                form
            }
        }
    }

    /// Lo que aparece después de guardar.
    ///
    /// La pantalla no se cierra sola. Cerrarse de golpe, como si acabara de
    /// guardarse un peso, convierte este momento en un trámite. Se queda, dice
    /// lo único que la app puede decir con honestidad —que nada se pierde— y
    /// espera.
    private var farewellMessage: some View {
        ZStack {
            Palette.background
                .ignoresSafeArea()

            card
                .padding(Spacing.xl)
        }
        // Sin barra de navegación: no hay nada para cancelar ni hacia dónde
        // volver, y un "Cancelar" acá arriba se leería como si algo estuviera a
        // medio hacer.
        .toolbar(.hidden, for: .navigationBar)
    }

    private var card: some View {
        VStack(spacing: Spacing.lg) {
            CompanionAvatar(companion: companion, size: 96)

            Text("\(companion.displayName) siempre va a estar con vos")
                .font(AppFont.sectionTitle)
                .foregroundStyle(Palette.onFarewellCard)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text("Su historial de salud entero lo guardamos acá: lo que anotaste, sus estudios y sus fotos. Podés volver cuando quieras.")
                .font(AppFont.body)
                .foregroundStyle(Palette.onFarewellCard)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Va aparte y más chico: cambia quién habla. Lo de arriba es sobre
            // el animal; esto es la app diciendo gracias, y mezclarlos le
            // sacaría peso a los dos.
            Text("Gracias por hacernos parte de su vida.")
                .font(AppFont.secondary)
                .foregroundStyle(Palette.onFarewellCardMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                dismiss()
            } label: {
                Text("Cerrar")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Palette.onFarewellCard)
                    .frame(maxWidth: .infinity, minHeight: Spacing.minimumTapTarget)
            }
            .buttonStyle(.plain)
            .padding(.top, Spacing.sm)
            .accessibilityIdentifier("farewell.close")
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        // El mensaje se anuncia como una sola cosa: quien navega con VoiceOver
        // lo escucha entero de una vez, sin ir juntando pedazos.
        .accessibilityElement(children: .combine)
    }

    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 32, style: .continuous)

        return FarewellBackground()
            .clipShape(shape)
    }

    private var form: some View {
        Group {
            Form {
                // Sin encabezado a propósito. "Qué pasa" convertía esto en un
                // apartado técnico de una pantalla que no lo es: acá alguien
                // está por marcar que su animal se murió. Primero se lo
                // acompaña, después se le explica, y nada de eso necesita un
                // título que lo anuncie.
                Section {
                    Text("El vínculo no desaparece, se transforma. Te abrazamos y te mandamos muchísimo cariño en este momento.")
                        .font(AppFont.body)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Su historia se guarda entera. Vas a poder entrar a su perfil y a todo lo que anotaste, cuando quieras.")
                        .font(AppFont.body)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Lo que cambia es que la app deja de pedirte cosas: se apagan los avisos de medicaciones y de vacunas, y \(companion.displayName) sale de la pantalla de todos los días.")
                        .font(AppFont.body)
                        .foregroundStyle(Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section {
                    DatePicker(selection: $date, in: ...Date(), displayedComponents: .date) {
                        Text("Fecha")
                    }
                } footer: {
                    Text("Si no la recordás con exactitud, una aproximada está bien. Se puede cambiar después.")
                        .foregroundStyle(Palette.inkMuted)
                }

                PrimaryButtonSection(
                    title: String(localized: "Guardar"),
                    identifier: "farewell.save",
                    action: save
                )
            }
            .navigationTitle(Text("\(companion.displayName) cruzó el arcoíris"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancelar")
                    }
                }
            }
            .alert(
                Text("No pudimos guardar"),
                isPresented: $saveFailed
            ) {
                Button("Entendido", role: .cancel) { saveFailed = false }
            } message: {
                Text("Podés intentar de nuevo en un momento.")
            }
        }
    }

    private func save() {
        companion.farewellDate = date

        do {
            try modelContext.save()
            ReminderSync.refresh(using: modelContext)
            isSaved = true
        } catch {
            companion.farewellDate = nil
            saveFailed = true
        }
    }
}
