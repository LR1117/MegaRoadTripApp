//
//  Allergen.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import Foundation

enum Allergen: String, Codable, CaseIterable, Identifiable {
    case gluten, dairy, nuts, peanuts, shellfish, eggs, soy, sesame, fish

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gluten:    return "Gluten"
        case .dairy:     return "Dairy"
        case .nuts:      return "Tree Nuts"
        case .peanuts:   return "Peanuts"
        case .shellfish: return "Shellfish"
        case .eggs:      return "Eggs"
        case .soy:       return "Soy"
        case .sesame:    return "Sesame"
        case .fish:      return "Fish"
        }
    }

    var icon: String {
        switch self {
        case .gluten:    return "🌾"
        case .dairy:     return "🥛"
        case .nuts:      return "🌰"
        case .peanuts:   return "🥜"
        case .shellfish: return "🦐"
        case .eggs:      return "🥚"
        case .soy:       return "🫘"
        case .sesame:    return "⚪️"
        case .fish:      return "🐟"
        }
    }
}
