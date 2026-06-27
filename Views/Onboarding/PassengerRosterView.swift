//
//  PassengerRosterView.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI

struct PassengerRosterView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @State private var showAddPassenger = false

    var body: some View {
        List {
            ForEach(tripVM.trip.passengers) { p in
                HStack {
                    Text(p.emoji).font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text(p.name).font(.headline)
                        if !p.dietaryProfile.restrictions.isEmpty {
                            Text(p.dietaryProfile.restrictions.map(\.displayName).joined(separator: ", "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if !p.dietaryProfile.allergens.isEmpty {
                            Text("⚠️ " + p.dietaryProfile.allergens.map(\.displayName).joined(separator: ", "))
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
            }
            .onDelete { tripVM.trip.passengers.remove(atOffsets: $0) }

            Button {
                showAddPassenger = true
            } label: {
                Label("Add Passenger", systemImage: "person.badge.plus")
            }
        }
        .navigationTitle("Who's in the Car?")
        .sheet(isPresented: $showAddPassenger) {
            AddPassengerView().environmentObject(tripVM)
        }
    }
}
