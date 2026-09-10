import Testing
@testable import AppSaludAnimales

/// La copia automática puede fallar de dos maneras y las dos fallan calladas si
/// nadie las mira: iCloud apagado y espacio agotado. La persona toca "activar",
/// no pasa nada visible, y queda creyendo que su información está a salvo.
///
/// Estos tests no comprueban que la sincronización funcione —eso se prueba con
/// dos teléfonos— sino que ningún caso pueda quedarse sin explicación.
struct CloudSyncTests {
    private static let casosQueNoSePueden: [CloudSyncAvailability] = [
        .iCloudApagado,
        .sinEspacio,
        .noHabilitada
    ]

    @Test
    func todoCasoQueFallaTieneTituloYExplicacion() {
        for caso in Self.casosQueNoSePueden {
            #expect(caso.titulo?.isEmpty == false, "\(caso) se quedó sin título")
            #expect(caso.explicacion?.isEmpty == false, "\(caso) se quedó sin explicación")
        }
    }

    /// Cuando se puede, no hay nada que avisar: un aviso vacío arriba de una
    /// pantalla que funciona es peor que ninguno.
    @Test
    func cuandoSePuedeNoHayNadaQueAvisar() {
        #expect(CloudSyncAvailability.disponible.titulo == nil)
        #expect(CloudSyncAvailability.disponible.explicacion == nil)
    }

    /// Los avisos dicen qué hacer, no solo qué pasó. Sin un camino de salida, la
    /// persona queda sabiendo que falló y sin saber cómo seguir.
    @Test
    func cadaAvisoDiceComoSeguir() {
        #expect(CloudSyncAvailability.iCloudApagado.explicacion?.contains("Ajustes") == true)
        #expect(CloudSyncAvailability.sinEspacio.explicacion?.contains("respaldo") == true)
        #expect(CloudSyncAvailability.noHabilitada.explicacion?.contains("respaldo") == true)
    }

    /// Ningún texto de esta función dice "sincronizar": nadie quiere
    /// sincronizar, la gente quiere no perder las cosas.
    @Test
    func losTextosNoHablanDeSincronizar() {
        let textos = Self.casosQueNoSePueden.flatMap { [$0.titulo, $0.explicacion] }

        for texto in textos.compactMap({ $0 }) {
            #expect(!texto.lowercased().contains("sincroniz"), "«\(texto)» habla de sincronizar")
        }
    }
}
