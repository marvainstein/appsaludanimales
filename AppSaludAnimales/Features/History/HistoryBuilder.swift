import Foundation

/// Referencia al registro real detrás de una línea del historial, para poder
/// abrirlo, cambiarle el estado o eliminarlo.
enum HealthRecordReference {
    case medication(Medication)
    case treatment(Treatment)
    case vaccination(Vaccination)
    case episode(HealthEpisode)
    case measurement(HealthMeasurement)
    case appointment(Appointment)
    case document(HealthDocument)
    case note(CompanionNote)
}

struct HistoryEntry: Identifiable {
    let id: UUID
    let title: String
    let detail: String?
    let date: Date
    let category: HealthCategory
    let badge: StatusBadge?
    let reference: HealthRecordReference
}

/// Un tramo del historial. Se agrupa por mes porque es como la gente recuerda:
/// "eso fue en mayo", no "eso fue hace 47 días".
struct HistorySection: Identifiable {
    let id: String
    let title: String
    let entries: [HistoryEntry]
}

/// Cómo se cuentan las tomas y las sesiones en una lista.
enum RhythmDetail {
    /// Juntas por día. Es lo que se mira en pantalla: dos tomas diarias durante
    /// un año serían setecientos treinta renglones repitiendo el mismo nombre.
    case byDay

    /// Un renglón por cada cambio de dosis, y uno por mes para las sesiones. Es
    /// lo que va al papel que se exporta: ahí lo que importa no es cada toma
    /// sino cuándo cambió algo. Si entre dos renglones no hay nada, siguió
    /// igual.
    case byChange
}

enum HistoryBuilder {
    /// Todo lo registrado, de lo más nuevo a lo más viejo.
    ///
    /// Un conjunto de categorías vacío significa "todo": es más simple que
    /// mantener seleccionadas todas las categorías por defecto y sincronizarlas
    /// cada vez que aparece una nueva.
    /// - Parameter rhythm: cómo se cuentan las tomas y las sesiones.
    static func entries(
        for companion: Companion,
        categories: Set<HealthCategory> = [],
        search: String = "",
        rhythm: RhythmDetail = .byDay
    ) -> [HistoryEntry] {
        var entries: [HistoryEntry] = []

        entries += companion.medications.map { medication in
            HistoryEntry(
                id: medication.id,
                title: medication.name,
                detail: medication.dose,
                date: medication.startDate,
                category: .medication,
                badge: medication.status().badge,
                reference: .medication(medication)
            )
        }

        entries += companion.treatments.map { treatment in
            HistoryEntry(
                id: treatment.id,
                title: treatment.name,
                detail: treatment.category,
                date: treatment.startDate,
                category: treatment.isPreventive ? .preventive : .treatment,
                badge: treatment.status().badge,
                reference: .treatment(treatment)
            )
        }

        entries += companion.vaccinations.map { vaccination in
            HistoryEntry(
                id: vaccination.id,
                title: vaccination.name,
                detail: vaccination.notes,
                date: vaccination.date,
                category: .vaccination,
                badge: nil,
                reference: .vaccination(vaccination)
            )
        }

        entries += companion.episodes.map { episode in
            HistoryEntry(
                id: episode.id,
                title: episode.symptom,
                detail: episode.episodeDescription ?? episode.intensityLabel,
                date: episode.date,
                category: .episode,
                badge: episode.status.badge,
                reference: .episode(episode)
            )
        }

        entries += companion.measurements.map { measurement in
            HistoryEntry(
                id: measurement.id,
                title: measurement.formattedValue,
                detail: measurement.kind.label,
                date: measurement.date,
                category: .measurement,
                badge: nil,
                reference: .measurement(measurement)
            )
        }

        entries += companion.appointments.map { appointment in
            HistoryEntry(
                id: appointment.id,
                title: appointment.title,
                detail: appointment.place,
                date: appointment.date,
                category: .appointment,
                badge: nil,
                reference: .appointment(appointment)
            )
        }

        entries += companion.documents.map { document in
            HistoryEntry(
                id: document.id,
                title: document.title,
                detail: document.category,
                date: document.date,
                category: .document,
                badge: nil,
                reference: .document(document)
            )
        }

        entries += companion.notes.map { note in
            HistoryEntry(
                id: note.id,
                title: note.text,
                detail: nil,
                date: note.date,
                category: .note,
                badge: nil,
                reference: .note(note)
            )
        }

        switch rhythm {
        case .byDay:
            entries += doseEntries(for: companion)
            entries += sessionEntries(for: companion)
        case .byChange:
            entries += doseChangeEntries(for: companion)
            entries += monthlySessionEntries(for: companion)
        }

        return entries
            .filter { categories.isEmpty || categories.contains($0.category) }
            .filter { entry in
                // Se busca en el título, en el detalle y en el nombre de la
                // categoría: quien escribe "vacuna" está buscando las vacunas,
                // aunque ninguna se llame así.
                TextSearch.matchesAny(
                    [entry.title, entry.detail, entry.category.label],
                    query: search
                )
            }
            .sorted { $0.date > $1.date }
    }

    /// Las tomas de cada medicación, agrupadas por día.
    ///
    /// El historial completo es la extensión de la actividad reciente, no una
    /// lista aparte: si anotás una toma a las 20:57, tiene que aparecer arriba
    /// de todo. Antes no aparecía en ningún lado y la medicación figuraba en la
    /// fecha en que empezó, así que un Contal que empezó en 2024 quedaba al
    /// fondo aunque se hubiera dado hoy.
    ///
    /// Agrupadas por día y no una por una porque dos tomas diarias durante un
    /// año son setecientos treinta renglones repitiendo el mismo nombre. El día
    /// es además la unidad con la que uno controla: lo que se quiere saber es si
    /// faltó alguna. Cada toma con su hora está en "Ver todas las tomas".
    private static func doseEntries(for companion: Companion) -> [HistoryEntry] {
        let calendar = Calendar.current

        return companion.medications.flatMap { medication in
            Dictionary(grouping: medication.doses) { calendar.startOfDay(for: $0.administeredAt) }
                .map { day, doses in
                    let latest = doses.map(\.administeredAt).max() ?? day

                    return HistoryEntry(
                        id: doses.map(\.id).min() ?? medication.id,
                        title: medication.name,
                        detail: doseDetail(for: doses),
                        date: latest,
                        category: .medication,
                        badge: nil,
                        reference: .medication(medication)
                    )
                }
        }
    }

    /// Cuántas tomas, y con qué dosis.
    ///
    /// Si en el día hubo dosis distintas las dice todas. Antes mostraba una
    /// cualquiera del montón y la presentaba como si fuera la de las tres:
    /// alguien que dio cinco pastillas, después dos y después una, leía que
    /// había dado tres veces una. Un resumen puede resumir; no puede afirmar
    /// algo que no pasó.
    private static func doseDetail(for doses: [MedicationDose]) -> String {
        let tomas = doses.count == 1
            ? String(localized: "1 toma")
            : String(localized: "\(doses.count) tomas")

        var vistas: [String] = []
        for dose in doses.sorted(by: { $0.administeredAt < $1.administeredAt }) {
            guard let value = dose.dose, !value.isEmpty, !vistas.contains(value) else { continue }
            vistas.append(value)
        }

        guard !vistas.isEmpty else { return tomas }
        return "\(tomas) · \(vistas.joined(separator: ", "))"
    }

    /// Cuándo cambió la dosis, y cuántas tomas hubo con cada una.
    ///
    /// Exportar toda la historia toma por toma es un delirio: son miles de
    /// renglones que repiten lo mismo. Lo que importa es el cambio. Si entre
    /// dos renglones no hay nada, es porque siguió tomando igual, y esa
    /// ausencia dice tanto como el dato.
    ///
    /// El renglón lleva la fecha en que la dosis empezó a usarse, así que cae
    /// en la línea de tiempo el día que cambió y no el día que se exportó.
    ///
    /// Esto cuenta lo anotado, sin interpretarlo. No dice si la dosis estuvo
    /// bien ni por qué cambió: dice qué se registró y cuándo.
    private static func doseChangeEntries(for companion: Companion) -> [HistoryEntry] {
        companion.medications.flatMap { medication -> [HistoryEntry] in
            let ordenadas = medication.doses.sorted { $0.administeredAt < $1.administeredAt }
            guard !ordenadas.isEmpty else { return [] }

            var tramos: [(dose: String?, desde: Date, cuantas: Int)] = []

            for toma in ordenadas {
                if var ultimo = tramos.last, ultimo.dose == toma.dose {
                    ultimo.cuantas += 1
                    tramos[tramos.count - 1] = ultimo
                } else {
                    tramos.append((dose: toma.dose, desde: toma.administeredAt, cuantas: 1))
                }
            }

            return tramos.map { tramo in
                HistoryEntry(
                    id: UUID(),
                    title: medication.name,
                    detail: changeDetail(dose: tramo.dose, count: tramo.cuantas),
                    date: tramo.desde,
                    category: .medication,
                    badge: nil,
                    reference: .medication(medication)
                )
            }
        }
    }

    private static func changeDetail(dose: String?, count: Int) -> String {
        let tomas = count == 1
            ? String(localized: "1 toma anotada")
            : String(localized: "\(count) tomas anotadas")

        guard let dose, !dose.isEmpty else { return tomas }
        return "\(dose) · \(tomas)"
    }

    /// Cuántas sesiones hubo cada mes.
    ///
    /// Es contar, no interpretar: la app no dice "pasó de dos veces por semana a
    /// cada quince días", dice cuántas veces fue cada mes y deja que eso se lea
    /// solo. Quien mira el papel sabe leer un ritmo mejor que nosotros.
    private static func monthlySessionEntries(for companion: Companion) -> [HistoryEntry] {
        let calendar = Calendar.current

        return companion.treatments.flatMap { treatment in
            Dictionary(grouping: treatment.sessions) { session in
                calendar.dateInterval(of: .month, for: session.attendedAt)?.start
                    ?? calendar.startOfDay(for: session.attendedAt)
            }
            .map { month, sessions in
                HistoryEntry(
                    id: UUID(),
                    title: treatment.name,
                    detail: sessions.count == 1
                        ? String(localized: "1 sesión en el mes")
                        : String(localized: "\(sessions.count) sesiones en el mes"),
                    date: sessions.map(\.attendedAt).max() ?? month,
                    category: treatment.isPreventive ? .preventive : .treatment,
                    badge: nil,
                    reference: .treatment(treatment)
                )
            }
        }
    }

    static func sections(
        for companion: Companion,
        categories: Set<HealthCategory> = [],
        search: String = "",
        calendar: Calendar = .current
    ) -> [HistorySection] {
        let grouped = Dictionary(
            grouping: entries(for: companion, categories: categories, search: search)
        ) { entry in
            calendar.dateComponents([.year, .month], from: entry.date)
        }

        return grouped
            .compactMap { components, entries -> HistorySection? in
                guard
                    let year = components.year,
                    let month = components.month,
                    let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1))
                else {
                    return nil
                }

                return HistorySection(
                    id: String(format: "%04d-%02d", year, month),
                    title: monthTitle(for: firstDay),
                    entries: entries.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.id > $1.id }
    }

    /// Solo las categorías que tienen algo registrado: un filtro que no filtra
    /// nada es ruido en la pantalla.
    static func availableCategories(for companion: Companion) -> [HealthCategory] {
        let present = Set(entries(for: companion).map(\.category))
        return HealthCategory.allCases.filter(present.contains)
    }

    private static func monthTitle(for date: Date) -> String {
        let title = date.formatted(.dateTime.month(.wide).year())
        return title.prefix(1).uppercased() + title.dropFirst()
    }
}
