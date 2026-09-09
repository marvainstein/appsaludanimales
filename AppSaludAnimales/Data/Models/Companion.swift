import Foundation
import SwiftData

/// Un compañero o compañera: perro o gato del que se lleva el seguimiento.
///
/// Los valores de enum se guardan como texto y no como tipo Codable: los
/// predicados de SwiftData trabajan mejor sobre tipos primitivos y la
/// sincronización con CloudKit no admite todos los tipos compuestos.
@Model
final class Companion {
    var id: UUID = UUID()
    var name: String = ""
    var nickname: String?
    var speciesRawValue: String = Species.dog.rawValue
    var breed: String?
    var sexRawValue: String = Sex.unknown.rawValue
    var birthDate: Date?
    var birthDatePrecisionRawValue: String = BirthDatePrecision.unknown.rawValue
    var relevantConditions: String?
    var allergies: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    /// El día que dejó de estar.
    ///
    /// Una app que sigue la salud de un animal, tarde o temprano, tiene que
    /// saber sostener esto. La única salida que ofrecía antes era eliminarlo, y
    /// eso borra toda su historia: es brutal, y da a entender que lo que se
    /// registró durante años dejó de importar.
    ///
    /// Con esta fecha cargada, la app deja de pedir cosas —se apagan los avisos,
    /// no aparece en lo de todos los días— y no deja de guardar nada. Se puede
    /// entrar a su perfil y a su historia cuando se quiera.
    var farewellDate: Date?

    @Attribute(.externalStorage)
    var photoData: Data?

    /// Descripción de la foto para VoiceOver, por ejemplo
    /// "Foto de Luli, galga negra y blanca".
    var photoAccessibilityDescription: String?

    @Relationship(deleteRule: .cascade, inverse: \Medication.companion)
    var medications: [Medication] = []

    @Relationship(deleteRule: .cascade, inverse: \Treatment.companion)
    var treatments: [Treatment] = []

    @Relationship(deleteRule: .cascade, inverse: \Vaccination.companion)
    var vaccinations: [Vaccination] = []

    @Relationship(deleteRule: .cascade, inverse: \HealthEpisode.companion)
    var episodes: [HealthEpisode] = []

    @Relationship(deleteRule: .cascade, inverse: \HealthMeasurement.companion)
    var measurements: [HealthMeasurement] = []

    @Relationship(deleteRule: .cascade, inverse: \Appointment.companion)
    var appointments: [Appointment] = []

    @Relationship(deleteRule: .cascade, inverse: \HealthDocument.companion)
    var documents: [HealthDocument] = []

    @Relationship(deleteRule: .cascade, inverse: \CompanionNote.companion)
    var notes: [CompanionNote] = []

    @Relationship(deleteRule: .nullify, inverse: \Professional.companions)
    var professionals: [Professional] = []

    @Relationship(deleteRule: .nullify, inverse: \ResponsiblePerson.companions)
    var responsiblePeople: [ResponsiblePerson] = []

    init(
        name: String = "",
        nickname: String? = nil,
        species: Species = .dog,
        breed: String? = nil,
        sex: Sex = .unknown,
        birthDate: Date? = nil,
        birthDatePrecision: BirthDatePrecision = .unknown
    ) {
        self.name = name
        self.nickname = nickname
        self.speciesRawValue = species.rawValue
        self.breed = breed
        self.sexRawValue = sex.rawValue
        self.birthDate = birthDate
        self.birthDatePrecisionRawValue = birthDatePrecision.rawValue
    }
}

extension Companion {
    var species: Species {
        get { Species(rawValue: speciesRawValue) ?? .dog }
        set { speciesRawValue = newValue.rawValue }
    }

    var sex: Sex {
        get { Sex(rawValue: sexRawValue) ?? .unknown }
        set { sexRawValue = newValue.rawValue }
    }

    var birthDatePrecision: BirthDatePrecision {
        get { BirthDatePrecision(rawValue: birthDatePrecisionRawValue) ?? .unknown }
        set { birthDatePrecisionRawValue = newValue.rawValue }
    }

    var isPresent: Bool { farewellDate == nil }

    /// La edad deja de correr el día que dejó de estar.
    ///
    /// Que la app siguiera sumándole años a un animal que ya no está sería una
    /// crueldad involuntaria, de las que solo se notan cuando pasan.
    var age: CompanionAge? {
        CompanionAgeCalculator.age(
            birthDate: birthDate,
            precision: birthDatePrecision,
            on: farewellDate ?? .now
        )
    }

    /// Un cumpleaños que ya no va a llegar no se anuncia.
    var nextBirthday: Date? {
        guard isPresent else { return nil }
        return CompanionAgeCalculator.nextBirthday(birthDate: birthDate)
    }

    /// Nombre para mostrar: el apodo gana cuando existe, porque es como la
    /// persona llama a su compañero todos los días.
    var displayName: String {
        if let nickname, !nickname.isEmpty { return nickname }
        return name
    }

    func activeMedications(on referenceDate: Date = .now) -> [Medication] {
        medications.filter { $0.status(on: referenceDate) == .active }
    }

    func activeTreatments(on referenceDate: Date = .now) -> [Treatment] {
        treatments.filter { $0.status(on: referenceDate) == .active }
    }

    /// Personas a cargo con la principal primero, y después por orden de carga.
    var orderedResponsiblePeople: [ResponsiblePerson] {
        responsiblePeople.sorted { lhs, rhs in
            lhs.isPrimary == rhs.isPrimary
                ? lhs.createdAt < rhs.createdAt
                : lhs.isPrimary
        }
    }

    var openEpisodes: [HealthEpisode] {
        episodes.filter { $0.status != .resolved }
    }

    var latestWeight: HealthMeasurement? {
        measurements
            .filter { $0.kind == .weight }
            .max { $0.date < $1.date }
    }
}
