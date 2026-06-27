//
//  TripViewModel.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI
import MapKit
import Combine

@MainActor
class TripViewModel: ObservableObject {

    // MARK: – Trip state
    @Published var trip: Trip = Trip()
    @Published var currentLocation: CLLocation?
    @Published var route: MKRoute?
    @Published var cameraPosition: MapCameraPosition = .automatic

    // MARK: – Discovery
    @Published var discoveredPlaces: [PlaceResult] = []
    @Published var isSearching = false
    @Published var activeCategory: PlaceCategory?

    // MARK: – UI state
    @Published var showPassengerSetup = false
    @Published var showResults = false

    // MARK: – Services
    private let locationService = LocationService()
    private let routeService = RouteService()
    private let placesService = PlacesService()
    private let filterService = FilterService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        locationService.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loc in self?.currentLocation = loc }
            .store(in: &cancellables)

        routeService.$route
            .receive(on: DispatchQueue.main)
            .sink { [weak self] r in self?.route = r }
            .store(in: &cancellables)
    }

    func startTrip() {
        locationService.requestPermission()
        guard let o = trip.origin?.coordinate, let d = trip.destination?.coordinate else { return }
        Task { await routeService.calculateRoute(from: o, to: d) }
    }

    func findNearby(category: PlaceCategory) {
        guard let location = currentLocation else { return }
        activeCategory = category
        isSearching = true

        Task {
            let raw = await placesService.search(category: category,
                                                 near: location.coordinate)
            var results: [PlaceResult]
            if category == .food {
                results = filterService.score(places: raw, for: trip.passengers)
            } else {
                results = raw.prefix(10).map {
                    PlaceResult(mapItem: $0, category: category,
                                distanceMiles: 0, compatibilityScore: 1,
                                compatibilityNotes: [], warnings: [])
                }
            }
            self.discoveredPlaces = results
            self.isSearching = false
            self.showResults = true
        }
    }
}
