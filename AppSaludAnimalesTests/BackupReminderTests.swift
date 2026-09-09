import Foundation
import Testing

@testable import AppSaludAnimales

/// La app pregunta por el respaldo, pero no molesta. Estas pruebas cuidan las
/// dos mitades de esa frase.
struct BackupReminderTests {
    private let now = Date.test(2026, 6, 1)

    @Test("A quien recién empieza no se le pide nada")
    func noPreguntaAlPrincipio() {
        #expect(
            BackupReminder.shouldOffer(
                lastBackup: nil,
                snoozedAt: nil,
                oldestRecord: .test(2026, 5, 28),
                now: now
            ) == false
        )
    }

    @Test("Con historia cargada y sin ningún respaldo, pregunta")
    func preguntaCuandoNuncaHuboRespaldo() {
        #expect(
            BackupReminder.shouldOffer(
                lastBackup: nil,
                snoozedAt: nil,
                oldestRecord: .test(2025, 1, 1),
                now: now
            )
        )
    }

    @Test("Con un respaldo reciente no dice nada")
    func calladoConRespaldoReciente() {
        #expect(
            BackupReminder.shouldOffer(
                lastBackup: .test(2026, 5, 1),
                snoozedAt: nil,
                oldestRecord: .test(2025, 1, 1),
                now: now
            ) == false
        )
    }

    @Test("Decir “ahora no” dura un mes, no hasta mañana")
    func elAhoraNoDuraUnMes() {
        let saidNo = Date.test(2026, 5, 20)

        #expect(
            BackupReminder.shouldOffer(
                lastBackup: nil,
                snoozedAt: saidNo,
                oldestRecord: .test(2025, 1, 1),
                now: now
            ) == false,
            "Volver a preguntar a los diez días de que dijeron que no es insistir"
        )

        #expect(
            BackupReminder.shouldOffer(
                lastBackup: nil,
                snoozedAt: saidNo,
                oldestRecord: .test(2025, 1, 1),
                now: .test(2026, 7, 15)
            )
        )
    }

    @Test("El mensaje cuenta el tiempo sin reprochar")
    func elMensajeNoReprocha() {
        let messages = [
            BackupReminder.message(lastBackup: nil, now: now),
            BackupReminder.message(lastBackup: .test(2025, 12, 1), now: now)
        ]

        for message in messages {
            #expect(!message.contains("!"), "Nada de signos de admiración: no es una alarma")
            #expect(!message.lowercased().contains("deberías"))
            #expect(!message.lowercased().contains("riesgo"))
        }
    }
}
