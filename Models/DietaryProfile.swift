//
//  DietaryProfile.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import Foundation

enum DietaryRestriction: String, Codable, CaseIterable, Identifiable {
    case vegetarian, vegan, halal, kosher, glutenFree, dairyFree, lowCarb, keto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vegetarian: return "Vegetarian"
        case .vegan:      return "Vegan"
        case .halal:      return "Halal"
        case .kosher:     return "Kosher"
        case .glutenFree: return "Gluten-Free"
        case .dairyFree:  return "Dairy-Free"
        case .lowCarb:    return "Low Carb"
        case .keto:       return "Keto"
        }
    }
}

enum CuisinePreference: String, Codable, CaseIterable, Identifiable {
    case american, mexican, italian, asian, mediterranean, fastFood, pizza, burgers, salads, bbq

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

struct DietaryProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var allergens: Set<Allergen> = []
    var restrictions: Set<DietaryRestriction> = []
    var cuisinePreferences: Set<CuisinePreference> = []
    var dislikedCuisines: Set<CuisinePreference> = []
}
