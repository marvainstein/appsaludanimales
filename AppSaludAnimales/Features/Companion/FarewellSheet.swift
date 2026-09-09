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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Su historia se guarda entera. Vas a poder entrar a su perfil y a todo lo que anotaste, cuando quieras.")
                        .font(AppFont.body)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Lo que cambia es que la app deja de pedirte cosas: se apagan los avisos de medicaciones y de vacunas, y \(companion.displayName) sale de la pantalla de todos los días.")
                        .font(AppFont.body)
                        .foregroundStyle(Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                } header: {
                    Text("Qué pasa")
                }

                Section {
                    DatePicker(selection: $date, in: ...Date(), displayedComponents: .date) {
                        Text("Fecha")
                    }
                } footer: {
                    Text("Si no la recordás con exactitud, una aproximada está bien. Se puede cambiar después.")
                }

                PrimaryButtonSection(
                    title: String(localized: "Guardar"),
                    identifier: "farewell.save",
                    action: save
                )
            }
            .navigationTitle(Text("\(companion.displayName) ya no está"))
            .navigationBarTitleDisplayMode(.inline)
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
            dismiss()
        } catch {
            companion.farewellDate = nil
            saveFailed = true
        }
    }
}
