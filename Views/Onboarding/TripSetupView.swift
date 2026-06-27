//
//  TripSetupView.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI
import MapKit

struct TripSetupView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @State private var originQuery = ""
    @State private var destQuery = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var searchingField: Field?
    @State private var navigateToPassengers = false

    enum Field { case origin, destination }

    var body: some View {
        NavigationStack {
            Form {
                Section("Starting Point") {
                    TextField("City, address, or landmark", text: $originQuery)
                        .onSubmit { search(for: .origin) }
                    if searchingField == .origin {
                        ForEach(searchResults, id: \.self) { item in
                            Button(item.name ?? "") {
                                tripVM.trip.origin = SavedLocation(
                                    name: item.name ?? "",
                                    coordinate: item.placemark.coordinate)
                                originQuery = item.name ?? ""
                                searchResults = []
                                searchingField = nil
                            }
                        }
                    }
                }

                Section("Destination") {
                    TextField("City, address, or landmark", text: $destQuery)
                        .onSubmit { search(for: .destination) }
                    if searchingField == .destination {
                        ForEach(searchResults, id: \.self) { item in
                            Button(item.name ?? "") {
                                tripVM.trip.destination = SavedLocation(
                                    name: item.name ?? "",
                                    coordinate: item.placemark.coordinate)
                                destQuery = item.name ?? ""
                                searchResults = []
                                searchingField = nil
                            }
                        }
                    }
                }

                Section {
                    NavigationLink("Who's in the car?", destination:
                        PassengerRosterView().environmentObject(tripVM)
                    )
                }
            }
            .navigationTitle("Plan Your Trip")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Let's Go") {
                        tripVM.startTrip()
                    }
                    .disabled(tripVM.trip.origin == nil || tripVM.trip.destination == nil)
                }
            }
        }
    }

    private func search(for field: Field) {
        searchingField = field
        let query = field == .origin ? originQuery : destQuery
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = query
        Task {
            if let resp = try? await MKLocalSearch(request: req).start() {
                searchResults = Array(resp.mapItems.prefix(5))
            }
        }
    }
}
