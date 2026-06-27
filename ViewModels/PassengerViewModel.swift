//
//  PassengerViewModel.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI
import Combine

class PassengerViewModel: ObservableObject {
    @Published var draft: Passenger = Passenger(name: "", emoji: "🧑", dietaryProfile: DietaryProfile())

    let emojiOptions = ["🧑","👦","👧","👨","👩","🧒","🧓","👴","👵"]

    func saveTo(trip: inout Trip) {
        guard !draft.name.isEmpty else { return }
        trip.passengers.append(draft)
        draft = Passenger(name: "", emoji: "🧑", dietaryProfile: DietaryProfile())
    }
}
