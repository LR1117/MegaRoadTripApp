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
    var name: String          { mapItem.name ?? "Unknown" }
    var category: PlaceCategory
    var distanceMiles: Double
    var compatibilityScore: Double  // 0.0 – 1.0, how well it suits the group
    var compatibilityNotes: [String]
    var warnings: [String]          // allergy / diet warnings
}

enum PlaceCategory: String, CaseIterable {
    case food       = "Food"
    case gas        = "Gas Station"
    case restroom   = "Rest Stop"
}
