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

    func calculateRoute(from origin: CLLocationCoordinate2D,
                        to destination: CLLocationCoordinate2D) async {
        await MainActor.run { isCalculating = true }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        if let response = try? await directions.calculate() {
            await MainActor.run {
                self.route = response.routes.first
                self.isCalculating = false
            }
        }
    }
}
