//
//  PlacesService.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import MapKit

class PlacesService {

    // Search near a coordinate for a given category
    func search(category: PlaceCategory,
                near coordinate: CLLocationCoordinate2D,
                radiusMeters: Double = 5000) async -> [MKMapItem] {

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = category.searchQuery
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radiusMeters,
            longitudinalMeters: radiusMeters
        )
        request.resultTypes = .pointOfInterest

        let search = MKLocalSearch(request: request)
        guard let response = try? await search.start() else { return [] }
        return response.mapItems
    }
}

private extension PlaceCategory {
    var searchQuery: String {
        switch self {
        case .food:     return "restaurant"
        case .gas:      return "gas station"
        case .restroom: return "rest stop"
        }
    }
}
