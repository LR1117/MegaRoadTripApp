//
//  FilterService.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import Foundation
import MapKit

class FilterService {

    // Score and filter results based on the passenger group's profiles
    func score(places: [MKMapItem],
               for passengers: [Passenger]) -> [PlaceResult] {

        // Collect group-wide hard blockers
        let allAllergens: Set<Allergen> = passengers
            .flatMap { $0.dietaryProfile.allergens }
            .reduce(into: Set()) { $0.insert($1) }

        let allRestrictions: Set<DietaryRestriction> = passengers
            .flatMap { $0.dietaryProfile.restrictions }
            .reduce(into: Set()) { $0.insert($1) }

        // Build cuisine preference counts
        var cuisineVotes: [CuisinePreference: Int] = [:]
        for p in passengers {
            for c in p.dietaryProfile.cuisinePreferences {
                cuisineVotes[c, default: 0] += 1
            }
        }

        return places.compactMap { item in
            guard let name = item.name else { return nil }
            let nameLower = name.lowercased()

            var warnings: [String] = []
            var notes: [String] = []
            var score = 0.5

            // Hard-block logic based on restaurant name keywords
            // In production replace with a real menu/dietary API
            if allRestrictions.contains(.vegan) && !nameLower.contains("vegan") {
                warnings.append("May not have vegan options")
                score -= 0.1
            }
            if allRestrictions.contains(.halal) && !nameLower.contains("halal") {
                warnings.append("Halal status unknown")
                score -= 0.15
            }
            if allAllergens.contains(.gluten) {
                warnings.append("Confirm gluten-free options")
                score -= 0.05
            }

            // Positive signals
            if nameLower.contains("grill") || nameLower.contains("kitchen") {
                score += 0.1
                notes.append("Likely broad menu")
            }

            // Map item distance from region center (placeholder — real distance
            // should be computed from live car location in TripViewModel)
            let distance = item.placemark.location.flatMap {
                CLLocation(latitude: item.placemark.coordinate.latitude,
                           longitude: item.placemark.coordinate.longitude)
                    .distance(from: $0)
            } ?? 0

            score = max(0, min(1, score))

            return PlaceResult(
                mapItem: item,
                category: .food,
                distanceMiles: distance / 1609.34,
                compatibilityScore: score,
                compatibilityNotes: notes,
                warnings: warnings
            )
        }
        .sorted { $0.compatibilityScore > $1.compatibilityScore }
    }
}
