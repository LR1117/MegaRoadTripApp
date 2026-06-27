//
//  PassengerViewModel.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI
import Combine

class PassengerViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var emoji: String = "🧑"
    @Published var isDriver: Bool = false
    @Published var dietaryProfile: DietaryProfile = DietaryProfile()

    let emojiOptions = ["🧑","👦","👧","👨","👩","🧒","🧓","👴","👵","🧔","👱"]

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    func buildPassenger() -> Passenger {
        Passenger(
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji,
            dietaryProfile: dietaryProfile,
            isDriver: isDriver
        )
    }

    func reset() {
        name = ""
        emoji = "🧑"
        isDriver = false
        dietaryProfile = DietaryProfile()
    }
}
