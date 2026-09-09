import SwiftUI

/// Qué es Huella, qué no hace, y de dónde viene.
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
                Text("Huella guarda la historia de salud de tu perro o de tu gato: las medicaciones, los síntomas, el peso, las vacunas, los turnos y los estudios del veterinario. Todo en un solo lugar, para poder contarlo cuando hace falta.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Qué es")
            }

            Section {
                Text("Huella no diagnostica, no interpreta y no aconseja. Anota lo que vos le contás y lo ordena. Si algo te preocupa, quien tiene que decirlo es un veterinario.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Lo que no hace")
            } footer: {
                Text("Esto no es una advertencia legal: es cómo está construida. La app no tiene forma de saber si un peso está bien o si un síntoma es grave, y fingir que sí sería peligroso.")
            }

            Section {
                Text("Tu información se guarda en tu teléfono y no se sube a internet. No hay cuenta, no hay servidores nuestros y no hay nada que vender. Compartir algo (el resumen en PDF, un documento, el respaldo) es siempre una decisión tuya.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)

                Text("La única excepción es buscar veterinarias cerca. Ahí, y solo en el momento en que tocás ese botón, la app le pregunta al mapa del teléfono qué hay alrededor tuyo. No se guarda ni tu ubicación ni el resultado.")
                    .font(AppFont.body)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Tus datos")
            }

            Section {
                Text("Huella es gratis y va a seguir siendo gratis. Sin versión paga, sin prueba por tiempo limitado, sin funciones reservadas y sin publicidad. Llevar la salud de un animal al que se quiere no puede depender de poder pagarla.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Cuánto cuesta")
            }

            Section {
                Text("Huella nace del seguimiento de la salud de Luli y Pripri, nuestras almas hechas perritas. Llevar su historia en papeles sueltos y en la memoria fue el problema real que esta app resuelve.")
                    .font(AppFont.body)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Esta app se las dedicamos a ellas y esperamos te sirva.")
                    .font(AppFont.body)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("De dónde viene")
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
        .navigationTitle(Text("Acerca de Huella"))
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
