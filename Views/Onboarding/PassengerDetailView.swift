//
//  PassengerDetailView.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/27/26.
//


import SwiftUI

struct PassengerDetailView: View {
    @EnvironmentObject var tripVM: TripViewModel
    let passenger: Passenger

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text(passenger.emoji).font(.system(size: 64))
                        Text(passenger.name).font(.title2.bold())
                        if passenger.isDriver {
                            Label("Driver", systemImage: "steeringwheel")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            if !passenger.dietaryProfile.restrictions.isEmpty {
                Section("Dietary Restrictions") {
                    ForEach(Array(passenger.dietaryProfile.restrictions), id: \.self) { r in
                        Label {
                            Text(r.displayName)
                        } icon: {
                            Text(r.icon) // Or an Image(systemName:) if it's an SF Symbol
                        }
                    }
                }
            }

            if !passenger.dietaryProfile.allergens.isEmpty {
                Section("Allergens") {
                    ForEach(Array(passenger.dietaryProfile.allergens), id: \.self) { a in
                        HStack {
                            Text(a.icon)
                            Text(a.displayName)
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            if !passenger.dietaryProfile.cuisinePreferences.isEmpty {
                Section("Favourite Cuisines") {
                    ForEach(Array(passenger.dietaryProfile.cuisinePreferences), id: \.self) { c in
                                Label {
                                    Text(c.displayName)
                                } icon: {
                                    Text(c.icon)
                                }
                    }
                }
            }
        }
        .navigationTitle(passenger.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
