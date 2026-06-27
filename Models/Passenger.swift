//
//  Passenger.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import Foundation

struct Passenger: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var emoji: String          // used as avatar (🧑, 👦, 👧, etc.)
    var dietaryProfile: DietaryProfile
    var isDriver: Bool = false
}
