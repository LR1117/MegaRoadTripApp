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

    var icon: String {
        switch self {
        case .vegetarian: return "🥗"
        case .vegan:      return "🌱"
        case .halal:      return "☪️"
        case .kosher:     return "✡️"
        case .glutenFree: return "🚫🌾"
        case .dairyFree:  return "🚫🥛"
        case .lowCarb:    return "📉"
        case .keto:       return "🥓"
        }
    }
}

enum CuisinePreference: String, Codable, CaseIterable, Identifiable {
    case american, mexican, italian, asian, mediterranean, fastFood, pizza, burgers, salads, bbq

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .american:      return "American"
        case .mexican:       return "Mexican"
        case .italian:       return "Italian"
        case .asian:         return "Asian"
        case .mediterranean: return "Mediterranean"
        case .fastFood:      return "Fast Food"
        case .pizza:         return "Pizza"
        case .burgers:       return "Burgers"
        case .salads:        return "Salads"
        case .bbq:           return "BBQ"
        }
    }

    var icon: String {
        switch self {
        case .american:      return "🦅"
        case .mexican:       return "🌮"
        case .italian:       return "🍝"
        case .asian:         return "🍜"
        case .mediterranean: return "🫙"
        case .fastFood:      return "🍟"
        case .pizza:         return "🍕"
        case .burgers:       return "🍔"
        case .salads:        return "🥗"
        case .bbq:           return "🔥"
        }
    }
}

struct DietaryProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var allergens: Set<Allergen> = []
    var restrictions: Set<DietaryRestriction> = []
    var cuisinePreferences: Set<CuisinePreference> = []
    var dislikedCuisines: Set<CuisinePreference> = []
}
