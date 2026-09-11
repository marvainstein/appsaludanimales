import SwiftUI

/// Qué es Estela, qué no hace, y de dónde viene.
///
/// Existe por tres razones. Alguien que la instala sin conocerla merece saber
/// con qué se metió. Apple pide poder ver de qué se trata y quién responde. Y
/// las promesas del producto —que no diagnostica, que los datos no salen del
/// teléfono, que es gratis— solo valen algo si están escritas donde cualquiera
/// las puede leer y reclamar.
struct AboutView: View {
    var body: some View {
        List {
            Section {
                Text("Estela nace del seguimiento de la salud de Luli y Pripri, nuestras almas hechas perritas. Llevar su historia en papeles sueltos y en la memoria fue el problema real que esta app resuelve.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Esta app se las dedicamos a ellas y esperamos te sirva.")
                    .font(AppFont.body)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Idea inicial")
                    .foregroundStyle(Palette.inkMuted)
            }

            Section {
                Text("Estela guarda la historia de salud de tu perro o de tu gato: las medicaciones, los síntomas, el peso, las vacunas, los turnos y los estudios del veterinario. Todo en un solo lugar, para poder contarlo cuando haga falta.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Qué es")
                    .foregroundStyle(Palette.inkMuted)
            }

            Section {
                Text("Estela no diagnostica, no interpreta y no aconseja. Anota lo que vos le contás y lo ordena. Si algo te preocupa, quien tiene que decidirlo es un veterinario.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Lo que no hace")
                    .foregroundStyle(Palette.inkMuted)
            }

            Section {
                Text("Tu información se guarda en tu teléfono. No hay cuenta, no hay servidores nuestros y no hay nada que vender.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Si preferís, en Respaldo podés activar que se guarde sola una copia en tu iCloud. Viene apagado y lo elegís vos.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Compartir algo —el resumen en PDF, un documento, el respaldo— es siempre una decisión tuya.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Tus datos")
                    .foregroundStyle(Palette.inkMuted)
            }

            Section {
                Text("Estela es gratis y va a seguir siendo gratis. Llevar la salud de un animal al que se quiere no puede depender de poder pagarla.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Cuánto cuesta")
                    .foregroundStyle(Palette.inkMuted)
            }

            Section {
                LabeledContent {
                    Text(version)
                } label: {
                    Text("Versión")
                }
                .accessibilityElement(children: .combine)
            }
        }
        .navigationTitle(Text("Acerca de Estela"))
        .navigationBarTitleDisplayMode(.inline)
        // Barra opaca: translúcida, el texto de sus botones se lee sobre lo que
        // pase por detrás, que puede ser cualquier cosa.
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String

        guard let build, build != short else { return short }

        return "\(short) (\(build))"
    }
}
