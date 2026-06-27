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
        case nil:       return "Results"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if tripVM.isSearching {
                    ProgressView("Searching…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if tripVM.discoveredPlaces.isEmpty {
                    ContentUnavailableView("Nothing Nearby",
                                          systemImage: "mappin.slash",
                                          description: Text("Try expanding your search radius."))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tripVM.discoveredPlaces) { place in
                                PlaceCardView(place: place) {
                                    finderVM.openInMaps(place)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(title)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { tripVM.showResults = false }
                }
            }
        }
#if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
#endif
    }
}

