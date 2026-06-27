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

    // MARK: – Trip data
    @Published var trip: Trip = Trip()
    @Published var tripStarted: Bool = false

    // MARK: – Map state
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var route: MKRoute?
    @Published var currentLocation: CLLocation?

    // MARK: – Discovery
    @Published var discoveredPlaces: [PlaceResult] = []
    @Published var isSearching = false
    @Published var activeCategory: PlaceCategory?
    @Published var showResults = false
    @Published var selectedPlace: PlaceResult?

    // MARK: – Errors
    @Published var routeError: String?
    @Published var isCalculatingRoute = false

    // MARK: – Services (internal)
    let locationService = LocationService()
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

        routeService.$isCalculating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.isCalculatingRoute = v }
            .store(in: &cancellables)

        routeService.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] e in self?.routeError = e }
            .store(in: &cancellables)
    }

    // MARK: – Public API

    var canStartTrip: Bool {
        trip.origin != nil &&
        trip.destination != nil &&
        !trip.passengers.isEmpty
    }

    func startTrip() {
        guard let o = trip.origin, let d = trip.destination else { return }
        locationService.requestPermission()
        Task {
            await routeService.calculateRoute(from: o.coordinate, to: d.coordinate)
            await MainActor.run {
                if self.route != nil {
                    self.tripStarted = true
                    self.fitMapToRoute()
                }
            }
        }
    }

    func openTurnByTurnInAppleMaps() {
        guard let o = trip.origin, let d = trip.destination else { return }
        routeService.openInAppleMaps(from: o, to: d)
    }

    func findNearby(category: PlaceCategory) {
        guard let location = currentLocation ?? syntheticLocationAlongRoute() else { return }
        activeCategory = category
        isSearching = true
        discoveredPlaces = []

        Task {
            var raw: [MKMapItem]
            if let route = route {
                raw = await placesService.searchAlongRoute(
                    category: category,
                    route: route,
                    currentLocation: location
                )
            } else {
                raw = await placesService.search(category: category, near: location.coordinate)
            }

            let results: [PlaceResult]
            if category == .food {
                results = filterService.score(places: raw,
                                              for: trip.passengers,
                                              currentLocation: location)
            } else {
                results = raw.prefix(10).map { item in
                    let dist = location.distance(
                        from: item.placemark.location ?? location
                    ) / 1609.34
                    return PlaceResult(
                        mapItem: item,
                        category: category,
                        distanceMiles: dist,
                        compatibilityScore: 1.0,
                        compatibilityNotes: [],
                        warnings: []
                    )
                }.sorted { $0.distanceMiles < $1.distanceMiles }
            }

            self.discoveredPlaces = results
            self.isSearching = false
            self.showResults = true
        }
    }

    func addPassenger(_ passenger: Passenger) {
        trip.passengers.append(passenger)
    }

    func removePassengers(at offsets: IndexSet) {
        trip.passengers.remove(atOffsets: offsets)
    }

    // MARK: – Private helpers

    private func fitMapToRoute() {
        guard let route = route else { return }
        let rect = route.polyline.boundingMapRect
        let padded = rect.insetBy(dx: -rect.width * 0.15, dy: -rect.height * 0.15)
        cameraPosition = .rect(padded)
    }

    // If GPS not yet available, place synthetic location at route start
    private func syntheticLocationAlongRoute() -> CLLocation? {
        guard let coord = trip.origin?.coordinate else { return nil }
        return CLLocation(latitude: coord.latitude, longitude: coord.longitude)
    }
}
