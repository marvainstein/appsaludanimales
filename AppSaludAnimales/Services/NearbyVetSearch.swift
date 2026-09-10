import CoreLocation
import MapKit
import Observation

/// Una veterinaria encontrada en el mapa del teléfono.
struct NearbyPlace: Identifiable {
    let id = UUID()
    let name: String
    let address: String?
    let phone: String?
    let coordinate: CLLocationCoordinate2D
    let distanceInMeters: Double

    var distanceDescription: String {
        DistanceDescription.short(meters: distanceInMeters)
    }
}

/// Busca veterinarias cerca.
///
/// **Esto es lo único de la app que habla con afuera.** Todo lo demás vive en el
/// teléfono y no sale nunca. Acá, en el momento en que alguien toca el botón, se
/// le pide la ubicación al sistema y se le pregunta al servicio de mapas de
/// Apple qué hay cerca.
///
/// Por eso: nunca se busca solo, nunca en segundo plano, y la pantalla lo dice
/// con todas las letras antes de pedir el permiso. No se guarda la ubicación ni
/// el resultado; cuando se cierra la pantalla, no queda nada.
///
/// Y lo que devuelve es una búsqueda en un mapa, no una lista revisada: puede
/// estar incompleta, puede tener lugares cerrados, y no dice cuál atiende
/// urgencias. La app ordena por distancia y no recomienda ninguna.
@Observable
final class NearbyVetSearch: NSObject, CLLocationManagerDelegate {
    enum Status {
        case idle
        case locating
        case searching
        case results([NearbyPlace])
        case empty
        case denied
        case failed
    }

    private(set) var status: Status = .idle

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        // Alcanza con saber en qué barrio está: pedir precisión de metros
        // gastaría batería y expondría más de lo necesario.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            status = .locating
            manager.requestWhenInUseAuthorization()

        case .denied, .restricted:
            status = .denied

        default:
            status = .locating
            manager.requestLocation()
        }
    }

    // MARK: - Ubicación
    //
    // El sistema llama a estos métodos en la cola principal, que es donde se
    // creó el administrador de ubicación.

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard case .locating = status else { return }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()

        case .denied, .restricted:
            status = .denied

        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        status = .searching
        search(around: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        status = .failed
    }

    // MARK: - Búsqueda

    /// Las búsquedas que se hacen, y se juntan.
    ///
    /// Una sola consulta se pierde clínicas enteras: el mapa las tiene cargadas
    /// con el nombre que usa cada una, y no todas dicen "veterinaria". Probando
    /// varias palabras y juntando los resultados aparecen bastantes más.
    private static let queries = [
        String(localized: "veterinaria"),
        String(localized: "veterinario"),
        String(localized: "clínica veterinaria"),
        String(localized: "hospital veterinario"),
        String(localized: "urgencias veterinarias")
    ]

    private func search(around location: CLLocation) {
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 12000,
            longitudinalMeters: 12000
        )

        Task { @MainActor in
            var found: [NearbyPlace] = []
            var failures = 0

            for query in Self.queries {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = query
                request.region = region
                request.resultTypes = .pointOfInterest

                do {
                    let response = try await MKLocalSearch(request: request).start()
                    found += response.mapItems.compactMap { place(from: $0, origin: location) }
                } catch {
                    failures += 1
                }
            }

            // Una pasada más por categoría, sin texto. Encuentra las que el
            // mapa tiene marcadas como servicio para animales aunque no digan
            // "veterinaria" en el nombre.
            //
            // Va aparte y no como filtro de las búsquedas de arriba: filtrar por
            // categoría es una lista blanca, no una ayuda. Puesto encima del
            // texto dejaba afuera a las que el mapa clasifica de otra manera,
            // como los hospitales de urgencias para animales.
            let byCategory = MKLocalPointsOfInterestRequest(
                center: location.coordinate,
                radius: 12000
            )
            byCategory.pointOfInterestFilter = MKPointOfInterestFilter(including: [.animalService])

            if let response = try? await MKLocalSearch(request: byCategory).start() {
                found += response.mapItems.compactMap { place(from: $0, origin: location) }
            }

            guard failures < Self.queries.count || !found.isEmpty else {
                status = .failed
                return
            }

            let places = Self.deduplicated(found).sorted { $0.distanceInMeters < $1.distanceInMeters }
            status = places.isEmpty ? .empty : .results(places)
        }
    }

    /// El mismo lugar aparece en varias búsquedas. Se lo reconoce por el nombre
    /// y por estar prácticamente en el mismo punto.
    private static func deduplicated(_ places: [NearbyPlace]) -> [NearbyPlace] {
        var seen: Set<String> = []

        return places.filter { place in
            let key = [
                place.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil),
                String(format: "%.4f", place.coordinate.latitude),
                String(format: "%.4f", place.coordinate.longitude)
            ].joined(separator: "|")

            return seen.insert(key).inserted
        }
    }

    private func place(from item: MKMapItem, origin: CLLocation) -> NearbyPlace? {
        guard let name = item.name else { return nil }

        let placemark = item.placemark
        let coordinate = placemark.coordinate
        let distance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            .distance(from: origin)

        return NearbyPlace(
            name: name,
            address: placemark.title,
            phone: item.phoneNumber,
            coordinate: coordinate,
            distanceInMeters: distance
        )
    }
}
