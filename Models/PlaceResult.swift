//
//  PlaceResult.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import Foundation
import MapKit

struct PlaceResult: Identifiable {
    var id: UUID = UUID()
    var mapItem: MKMapItem
    var category: PlaceCategory
    var distanceMiles: Double
    var compatibilityScore: Double  // 0.0 – 1.0
    var compatibilityNotes: [String]
    var warnings: [String]

    var name: String { mapItem.name ?? "Unknown" }

    var phoneNumber: String? { mapItem.phoneNumber }

    var address: String {
        let p = mapItem.placemark
        let parts = [p.subThoroughfare, p.thoroughfare, p.locality, p.administrativeArea]
            .compactMap { $0 }
        return parts.joined(separator: " ")
    }
}

enum PlaceCategory: String, CaseIterable {
    case food     = "Food"
    case gas      = "Gas Station"
    case restroom = "Rest Stop"

    var icon: String {
        switch self {
        case .food:     return "fork.knife"
        case .gas:      return "fuelpump.fill"
        case .restroom: return "toilet.fill"
        }
    }

    var color: String {
        switch self {
        case .food:     return "orange"
        case .gas:      return "green"
        case .restroom: return "blue"
        }
    }

    var searchQuery: String {
        switch self {
        case .food:     return "restaurant"
        case .gas:      return "gas station"
        case .restroom: return "rest stop"
        }
    }
}
