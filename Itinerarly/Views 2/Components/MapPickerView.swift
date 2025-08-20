import SwiftUI
import MapKit
import CoreLocation

struct MapPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let cityName: String
    let initialCoordinate: CLLocationCoordinate2D?
    let onPicked: (CLLocation, String) -> Void

    @State private var mapCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedAddress: String = ""
    @State private var isGeocoding = false

    var body: some View {
        ZStack(alignment: .top) {
            MapRepresentable(center: $mapCenter, region: $region, selectedCoordinate: $selectedCoordinate) { coord in
                reverseGeocode(coord)
            }
            .ignoresSafeArea()

            VStack(spacing: 8) {
                HStack {
                    Text("Touchez et maintenez pour placer un point")
                        .font(.callout)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    Spacer()
                }
                .padding()

                Spacer()

                VStack(spacing: 8) {
                    if let _ = selectedCoordinate {
                        Text(selectedAddress.isEmpty ? (isGeocoding ? "Recherche de l'adresse…" : "Adresse inconnue") : selectedAddress)
                            .font(.footnote)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                    }
                    HStack {
                        Button("Annuler") { dismiss() }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.bordered)
                        Button("Confirmer") {
                            if let coord = selectedCoordinate {
                                let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                                let address = selectedAddress.isEmpty ? String(format: "%.6f, %.6f", coord.latitude, coord.longitude) : selectedAddress
                                onPicked(location, address)
                                dismiss()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedCoordinate == nil)
                    }
                }
                .padding()
            }
        }
        .onAppear { configureInitialRegion() }
    }

    private func configureInitialRegion() {
        if let initial = initialCoordinate {
            mapCenter = initial
            region.center = initial
            return
        }
        // Essayer la position système courante (blue dot) si autorisée
        let clm = CLLocationManager()
        if clm.authorizationStatus == .authorizedWhenInUse || clm.authorizationStatus == .authorizedAlways {
            if let current = clm.location?.coordinate {
                mapCenter = current
                region = MKCoordinateRegion(center: current, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
                return
            }
        }
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(cityName) { placemarks, _ in
            if let coord = placemarks?.first?.location?.coordinate {
                mapCenter = coord
                region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
            }
        }
    }

    private func reverseGeocode(_ coord: CLLocationCoordinate2D) {
        isGeocoding = true
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            isGeocoding = false
            selectedCoordinate = coord
            if let pm = placemarks?.first {
                var comps: [String] = []
                if let name = pm.name { comps.append(name) }
                if let locality = pm.locality { comps.append(locality) }
                if let postalCode = pm.postalCode { comps.append(postalCode) }
                if let country = pm.country { comps.append(country) }
                selectedAddress = comps.joined(separator: ", ")
            } else {
                selectedAddress = String(format: "%.6f, %.6f", coord.latitude, coord.longitude)
            }
        }
    }
}

private struct MapRepresentable: UIViewRepresentable {
    @Binding var center: CLLocationCoordinate2D
    @Binding var region: MKCoordinateRegion
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    var onLongPress: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.setRegion(region, animated: false)
        map.showsUserLocation = true
        map.userTrackingMode = .follow
        let lp = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        map.addGestureRecognizer(lp)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: false)
        uiView.removeAnnotations(uiView.annotations)
        if let selected = selectedCoordinate {
            let ann = MKPointAnnotation()
            ann.coordinate = selected
            uiView.addAnnotation(ann)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private let parent: MapRepresentable
        init(_ parent: MapRepresentable) { self.parent = parent }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let map = gesture.view as? MKMapView else { return }
            if gesture.state == .began {
                let point = gesture.location(in: map)
                let coord = map.convert(point, toCoordinateFrom: map)
                parent.selectedCoordinate = coord
                parent.onLongPress(coord)
            }
        }
    }
}


