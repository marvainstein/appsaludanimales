import MapKit
import SwiftUI

/// Veterinarias cerca, para el momento en que la de siempre no está.
///
/// El mapa es una ayuda; la lista es la información. Quien no ve el mapa recibe
/// lo mismo: nombre, dirección, a qué distancia, y los dos botones que importan.
struct NearbyVetsView: View {
    @State private var search = NearbyVetSearch()
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            switch search.status {
            case .idle:
                explanationSection

            case .locating, .searching:
                Section {
                    HStack(spacing: Spacing.md) {
                        ProgressView()
                        Text("Buscando veterinarias cerca…")
                            .font(AppFont.body)
                    }
                    .frame(minHeight: Spacing.minimumTapTarget)
                    .accessibilityElement(children: .combine)
                }

            case let .results(places):
                mapSection(places)
                resultsSection(places)

            case .empty:
                message(
                    title: String(localized: "No encontramos veterinarias cerca"),
                    detail: String(localized: "Puede ser que el mapa no las tenga cargadas en esta zona. Probá buscando en la aplicación de mapas del teléfono.")
                )

            case .denied:
                message(
                    title: String(localized: "La app no tiene permiso para ver dónde estás"),
                    detail: String(localized: "Podés dárselo desde Ajustes del teléfono, en Privacidad y seguridad, Localización. Sin eso no se puede buscar por cercanía.")
                )

            case .failed:
                message(
                    title: String(localized: "No pudimos completar la búsqueda"),
                    detail: String(localized: "Puede ser un problema de conexión. Podés intentar de nuevo en un momento.")
                )
            }
        }
        .navigationTitle(Text("Veterinarias cerca"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Antes de buscar

    /// Lo que va a pasar, dicho antes de que pase.
    private var explanationSection: some View {
        Section {
            Text("Para buscar veterinarias cerca, la app le pregunta al mapa del teléfono qué hay alrededor tuyo. Es lo único de la app que sale a internet, pasa solo cuando tocás el botón, y no se guarda ni tu ubicación ni el resultado.")
                .font(AppFont.body)
                .fixedSize(horizontal: false, vertical: true)

            PrimaryButton(
                title: String(localized: "Buscar veterinarias cerca"),
                identifier: "nearbyVets.search"
            ) {
                search.start()
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } footer: {
            Text("Lo que aparece es una búsqueda en el mapa, no una lista revisada. Puede estar incompleta, puede haber lugares cerrados, y no dice cuál atiende urgencias. La app las ordena por distancia y no recomienda ninguna.")
        }
    }

    // MARK: - Resultados

    private func mapSection(_ places: [NearbyPlace]) -> some View {
        Section {
            Map {
                UserAnnotation()

                ForEach(places) { place in
                    Marker(place.name, systemImage: "cross.case", coordinate: place.coordinate)
                        .tint(Palette.accentFill)
                }
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .padding(.vertical, Spacing.xs)
            // Todo lo que muestra el mapa está abajo en texto. Hacer recorrer un
            // mapa con VoiceOver, en una emergencia, sería peor que no tenerlo.
            .accessibilityHidden(true)
        }
    }

    private func resultsSection(_ places: [NearbyPlace]) -> some View {
        Section {
            ForEach(places) { place in
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(place.name)
                        .font(AppFont.cardTitle)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(place.distanceDescription)
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)

                    if let address = place.address {
                        Text(address)
                            .font(AppFont.secondary)
                            .foregroundStyle(Palette.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: Spacing.lg) {
                        if let phone = place.phone, let url = PhoneNumberLink.callURL(for: phone) {
                            Button {
                                openURL(url)
                            } label: {
                                Label {
                                    Text("Llamar")
                                } icon: {
                                    Image(systemName: "phone.fill")
                                }
                                .frame(minHeight: Spacing.minimumTapTarget)
                            }
                            .accessibilityLabel(Text("Llamar a \(place.name)"))
                        }

                        Button {
                            openInMaps(place)
                        } label: {
                            Label {
                                Text("Cómo llegar")
                            } icon: {
                                Image(systemName: "map")
                            }
                            .frame(minHeight: Spacing.minimumTapTarget)
                        }
                        .accessibilityLabel(Text("Cómo llegar a \(place.name)"))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.accent)
                }
                .padding(.vertical, Spacing.xs)
            }
        } header: {
            Text("Ordenadas por distancia")
        } footer: {
            Text("Es una búsqueda en el mapa, no una lista revisada. Puede estar incompleta y no dice cuál atiende urgencias.")
        }
    }

    private func message(title: String, detail: String) -> some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(title)
                    .font(AppFont.cardTitle)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(AppFont.body)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Spacing.xs)
            .accessibilityElement(children: .combine)
        }
    }

    private func openInMaps(_ place: NearbyPlace) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
        item.name = place.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
