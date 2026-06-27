//
//  PlacesService.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import MapKit

class PlacesService {

    func search(category: PlaceCategory,
                near coordinate: CLLocationCoordinate2D,
                radiusMeters: Double = 8000) async -> [MKMapItem] {

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = category.searchQuery
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radiusMeters,
            longitudinalMeters: radiusMeters
        )
        request.resultTypes = .pointOfInterest

        guard let response = try? await MKLocalSearch(request: request).start() else { return [] }
        return response.mapItems
    }

    // Search along the route, near an upcoming waypoint
    func searchAlongRoute(category: PlaceCategory,
                          route: MKRoute,
                          currentLocation: CLLocation,
                          lookAheadMeters: Double = 15000) async -> [MKMapItem] {
        // Find the route step that is ~lookAheadMeters ahead
        var accumulated = 0.0
        var targetCoordinate = currentLocation.coordinate

        for step in route.steps {
            accumulated += step.distance
            if accumulated >= lookAheadMeters {
                targetCoordinate = step.polyline.coordinate
                break
            }
        }

        return await search(category: category, near: targetCoordinate, radiusMeters: 5000)
    }
}
