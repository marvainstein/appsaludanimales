import Foundation
import SwiftData
import Testing

@testable import AppSaludAnimales

struct PhoneNumberLinkTests {
    @Test(arguments: [
        "(011) 4567-8900",
        "011 4567 8900",
        "011.4567.8900"
    ])
    func aceptaLosTelefonosComoLosEscribeLaGente(phone: String) {
        #expect(PhoneNumberLink.callURL(for: phone)?.absoluteString == "tel:01145678900")
    }

    @Test
    func conservaElPrefijoInternacional() {
        #expect(
            PhoneNumberLink.callURL(for: "+54 9 11 4567-8900")?.absoluteString
                == "tel:+5491145678900"
        )
    }

    @Test(arguments: ["", "   ", "sin teléfono", "12"])
    func noArmaUnEnlaceConLoQueNoEsUnTelefono(text: String) {
        #expect(PhoneNumberLink.callURL(for: text) == nil)
    }

    @Test
    func sinTelefonoNoHayEnlace() {
        #expect(PhoneNumberLink.callURL(for: nil) == nil)
    }
}

struct EmergencyProfileTests {
    private let container: ModelContainer
    private let context: ModelContext

    init() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    @Test
    func muestraLoQueRecibeAhoraYNoLoQueYaTermino() throws {
        let companion = try makeCompanion()
        companion.medications.append(
            Medication(name: "Gabapentina", dose: "media pastilla", startDate: .test(2024, 5, 1))
        )
        companion.medications.append(
            Medication(
                name: "Amoxicilina",
                startDate: .test(2024, 1, 1),
                endDate: .test(2024, 2, 1)
            )
        )
        companion.treatments.append(
            Treatment(name: "Fisioterapia", startDate: .test(2024, 4, 1))
        )

        let profile = EmergencyProfileBuilder.profile(for: companion, on: .test(2024, 5, 20))

        #expect(profile.medications == ["Gabapentina · media pastilla"])
        #expect(profile.treatments == ["Fisioterapia"])
    }

    @Test
    func prefiereElVeterinarioDeCabeceraSobreOtrosProfesionales() throws {
        let companion = try makeCompanion()
        let otro = Professional(name: "Kinesióloga", role: "Fisioterapia", phone: "1111")
        let cabecera = Professional(
            name: "Dra. Molina",
            phone: "(011) 4567-8900",
            isPrimaryVeterinarian: true
        )
        companion.professionals.append(contentsOf: [otro, cabecera])

        let profile = EmergencyProfileBuilder.profile(for: companion, on: .test(2024, 5, 20))

        #expect(profile.veterinarian?.name == "Dra. Molina")
        #expect(profile.veterinarian?.callURL?.absoluteString == "tel:01145678900")
    }

    @Test
    func siNoHayVeterinarioDeCabeceraUsaElPrimeroCargado() throws {
        let companion = try makeCompanion()
        companion.professionals.append(Professional(name: "Kinesióloga", phone: "1111111"))

        let profile = EmergencyProfileBuilder.profile(for: companion, on: .test(2024, 5, 20))

        #expect(profile.veterinarian?.name == "Kinesióloga")
    }

    @Test
    func avisaQueFaltanLosTelefonosSinSenialarloComoUnError() throws {
        let companion = try makeCompanion()

        let profile = EmergencyProfileBuilder.profile(for: companion, on: .test(2024, 5, 20))

        #expect(profile.missingEssentials.count == 2)
    }

    @Test
    func unContactoSinTelefonoSigueContandoComoFaltante() throws {
        let companion = try makeCompanion()
        companion.professionals.append(
            Professional(name: "Dra. Molina", isPrimaryVeterinarian: true)
        )

        let profile = EmergencyProfileBuilder.profile(for: companion, on: .test(2024, 5, 20))

        #expect(profile.veterinarian?.name == "Dra. Molina")
        #expect(profile.missingEssentials.contains { $0.contains("veterinario") })
    }

    @Test
    func muestraTodasLasPersonasACargoConLaPrincipalPrimero() throws {
        let companion = try makeCompanion()
        companion.responsiblePeople.append(ResponsiblePerson(name: "Bruno", phone: "1133445566"))
        companion.responsiblePeople.append(
            ResponsiblePerson(name: "Marina", phone: "1122334455", isPrimary: true)
        )

        let profile = EmergencyProfileBuilder.profile(for: companion, on: .test(2024, 5, 20))

        #expect(profile.responsiblePeople.map(\.name) == ["Marina", "Bruno"])
    }

    @Test
    func alcanzaConQueUnaPersonaACargoTengaTelefono() throws {
        let companion = try makeCompanion()
        companion.professionals.append(
            Professional(name: "Dra. Molina", phone: "1145678900", isPrimaryVeterinarian: true)
        )
        companion.responsiblePeople.append(ResponsiblePerson(name: "Bruno", isPrimary: true))
        companion.responsiblePeople.append(ResponsiblePerson(name: "Marina", phone: "1122334455"))

        let profile = EmergencyProfileBuilder.profile(for: companion, on: .test(2024, 5, 20))

        #expect(profile.missingEssentials.isEmpty)
    }

    @Test
    func noQuedaNadaPendienteCuandoLosDosTelefonosEstanCargados() throws {
        let companion = try makeCompanion()
        companion.professionals.append(
            Professional(name: "Dra. Molina", phone: "1145678900", isPrimaryVeterinarian: true)
        )
        companion.responsiblePeople.append(
            ResponsiblePerson(name: "Marina", phone: "1122334455", isPrimary: true)
        )

        let profile = EmergencyProfileBuilder.profile(for: companion, on: .test(2024, 5, 20))

        #expect(profile.missingEssentials.isEmpty)
    }

    @Test
    func laEdadAproximadaSeComunicaComoAproximada() throws {
        let companion = try makeCompanion(
            birthDate: .test(2020, 1, 1),
            precision: .yearOnly
        )

        let profile = EmergencyProfileBuilder.profile(for: companion, on: .test(2024, 5, 20))

        #expect(profile.ageText?.contains("Aproximadamente") == true)
    }

    private func makeCompanion(
        birthDate: Date? = nil,
        precision: BirthDatePrecision = .unknown
    ) throws -> Companion {
        let companion = Companion(
            name: "Luli",
            species: .dog,
            birthDate: birthDate,
            birthDatePrecision: precision
        )
        context.insert(companion)
        return companion
    }
}
