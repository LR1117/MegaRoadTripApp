//
//  PlaceResultsSheet.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI

struct PlaceResultsSheet: View {
    @EnvironmentObject var tripVM: TripViewModel
    @StateObject private var finderVM = PlaceFinderViewModel()

    var title: String {
        switch tripVM.activeCategory {
        case .food:     return "Food Near You"
        case .gas:      return "Gas Stations"
        case .restroom: return "Rest Stops"
        case nil:       return "Nearby"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if tripVM.isSearching {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Finding the best options…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if tripVM.discoveredPlaces.isEmpty {
                    ContentUnavailableView(
                        "Nothing Found",
                        systemImage: "mappin.slash",
                        description: Text("Try searching in a different area.")
                    )

                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if tripVM.activeCategory == .food {
                                GroupSummaryBanner(passengers: tripVM.trip.passengers)
                                    .padding(.horizontal)
                            }

                            ForEach(tripVM.discoveredPlaces) { place in
                                PlaceCardView(place: place) {
                                    finderVM.openInMaps(place)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { tripVM.showResults = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// A small banner summarising the group's combined constraints
struct GroupSummaryBanner: View {
    let passengers: [Passenger]

    var allAllergens: [Allergen] {
        Array(Set(passengers.flatMap { Array($0.dietaryProfile.allergens) }))
    }
    var allRestrictions: [DietaryRestriction] {
        Array(Set(passengers.flatMap { Array($0.dietaryProfile.restrictions) }))
    }

    var body: some View {
        if allAllergens.isEmpty && allRestrictions.isEmpty { EmptyView() }
        else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Filtered for your group")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(allRestrictions, id: \.self) { r in
                            Text("\(r.icon) \(r.displayName)")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.green.opacity(0.12))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                        ForEach(allAllergens, id: \.self) { a in
                            Text("⚠️ No \(a.displayName)")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.orange.opacity(0.12))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
