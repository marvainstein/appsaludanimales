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

    private func search(around location: CLLocation) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = String(localized: "veterinaria")
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 8000,
            longitudinalMeters: 8000
        )

        Task { @MainActor in
            do {
                let response = try await MKLocalSearch(request: request).start()
                let places = response.mapItems
                    .compactMap { place(from: $0, origin: location) }
                    .sorted { $0.distanceInMeters < $1.distanceInMeters }

                status = places.isEmpty ? .empty : .results(places)
            } catch {
                status = .failed
            }
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
