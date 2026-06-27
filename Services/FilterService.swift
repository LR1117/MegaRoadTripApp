//
//  FilterService.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import Foundation
import MapKit

class FilterService {

    func score(places: [MKMapItem],
               for passengers: [Passenger],
               currentLocation: CLLocation?) -> [PlaceResult] {

        let allAllergens: Set<Allergen> = passengers
            .flatMap { $0.dietaryProfile.allergens }
            .reduce(into: []) { $0.insert($1) }

        let allRestrictions: Set<DietaryRestriction> = passengers
            .flatMap { $0.dietaryProfile.restrictions }
            .reduce(into: []) { $0.insert($1) }

        var cuisineVotes: [CuisinePreference: Int] = [:]
        for p in passengers {
            for c in p.dietaryProfile.cuisinePreferences {
                cuisineVotes[c, default: 0] += 1
            }
        }
        let topCuisines = cuisineVotes.sorted { $0.value > $1.value }.prefix(3).map(\.key)

        return places.compactMap { item in
            guard let name = item.name else { return nil }
            let nameLower = name.lowercased()
            var warnings: [String] = []
            var notes: [String] = []
            var score = 0.5

            // ── Dietary restriction checks ──────────────────────────────────
            if allRestrictions.contains(.vegan) {
                if nameLower.contains("vegan") || nameLower.contains("plant") {
                    score += 0.2; notes.append("Vegan-friendly")
                } else {
                    score -= 0.15; warnings.append("Vegan options may be limited")
                }
            }

            if allRestrictions.contains(.vegetarian) {
                if nameLower.contains("veggie") || nameLower.contains("garden") || nameLower.contains("green") {
                    score += 0.1; notes.append("Vegetarian-friendly")
                } else {
                    warnings.append("Confirm vegetarian options")
                }
            }

            if allRestrictions.contains(.halal) {
                if nameLower.contains("halal") {
                    score += 0.25; notes.append("Halal certified")
                } else {
                    score -= 0.2; warnings.append("Halal status unconfirmed")
                }
            }

            if allRestrictions.contains(.kosher) {
                if nameLower.contains("kosher") {
                    score += 0.25; notes.append("Kosher certified")
                } else {
                    score -= 0.2; warnings.append("Kosher status unconfirmed")
                }
            }

            if allRestrictions.contains(.glutenFree) {
                if nameLower.contains("gluten") {
                    score += 0.1; notes.append("Gluten-free options available")
                } else {
                    warnings.append("Ask about gluten-free options")
                }
            }

            // ── Allergen warnings ──────────────────────────────────────────
            if allAllergens.contains(.nuts) || allAllergens.contains(.peanuts) {
                warnings.append("⚠️ Nut allergy in group — verify with staff")
            }
            if allAllergens.contains(.shellfish) {
                if nameLower.contains("seafood") || nameLower.contains("fish") || nameLower.contains("crab") {
                    score -= 0.3; warnings.append("⚠️ Shellfish allergy — high risk venue")
                }
            }
            if allAllergens.contains(.dairy) {
                warnings.append("Ask about dairy-free options")
            }

            // ── Cuisine preference bonus ───────────────────────────────────
            for cuisine in topCuisines {
                let keywords = cuisineKeywords(cuisine)
                if keywords.contains(where: { nameLower.contains($0) }) {
                    score += 0.15
                    notes.append("Matches \(cuisine.displayName) preference")
                    break
                }
            }

            // ── Category bonuses ───────────────────────────────────────────
            if let category = item.pointOfInterestCategory {
                switch category {
                case .restaurant: score += 0.1
                case .cafe:       score += 0.05
                case .fastFood:   score += 0.02
                default: break
                }
            }

            // ── Distance from current location ─────────────────────────────
            var distanceMiles = 0.0
            if let loc = currentLocation,
               let itemLoc = item.placemark.location {
                distanceMiles = loc.distance(from: itemLoc) / 1609.34
                // Slight penalty for being far
                if distanceMiles > 2 { score -= 0.05 }
                if distanceMiles > 5 { score -= 0.1 }
            }

            score = max(0, min(1, score))

            return PlaceResult(
                mapItem: item,
                category: .food,
                distanceMiles: distanceMiles,
                compatibilityScore: score,
                compatibilityNotes: notes,
                warnings: warnings
            )
        }
        .sorted { $0.compatibilityScore > $1.compatibilityScore }
    }

    // MARK: - Helpers

    private func cuisineKeywords(_ cuisine: CuisinePreference) -> [String] {
        switch cuisine {
        case .american:      return ["diner", "american", "grill", "smokehouse"]
        case .mexican:       return ["mexican", "taco", "burrito", "cantina", "tex-mex"]
        case .italian:       return ["italian", "pizza", "pasta", "trattoria", "ristorante"]
        case .asian:         return ["asian", "chinese", "japanese", "thai", "sushi", "ramen", "pho"]
        case .mediterranean: return ["mediterranean", "greek", "falafel", "hummus", "shawarma"]
        case .fastFood:      return ["mcdonald", "burger king", "wendy", "chick-fil", "subway", "taco bell"]
        case .pizza:         return ["pizza", "pizzeria", "pie"]
        case .burgers:       return ["burger", "burgers", "smash", "shake shack", "five guys"]
        case .salads:        return ["salad", "greens", "sweetgreen", "chopt"]
        case .bbq:           return ["bbq", "barbeque", "barbecue", "smokehouse", "pit"]
        }
    }
}
