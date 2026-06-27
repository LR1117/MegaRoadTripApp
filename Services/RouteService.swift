//
//  RouteService.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import MapKit
import Combine

class RouteService: ObservableObject {
    @Published var route: MKRoute?
    @Published var isCalculating = false
    @Published var error: String?

    func calculateRoute(from origin: CLLocationCoordinate2D,
                        to destination: CLLocationCoordinate2D) async {
        await MainActor.run {
            isCalculating = true
            error = nil
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            await MainActor.run {
                self.route = response.routes.first
                self.isCalculating = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isCalculating = false
            }
        }
    }

    // Open the full turn-by-turn directions in Apple Maps
    func openInAppleMaps(from origin: SavedLocation, to destination: SavedLocation) {
        let originItem = MKMapItem(placemark: MKPlacemark(coordinate: origin.coordinate))
        originItem.name = origin.name

        let destItem = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        destItem.name = destination.name

        MKMapItem.openMaps(
            with: [originItem, destItem],
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                MKLaunchOptionsShowsTrafficKey: true
            ]
        )
    }
}
