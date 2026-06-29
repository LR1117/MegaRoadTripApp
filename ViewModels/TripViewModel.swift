//
//  TripViewModel.swift
//  MegaRoadTripApp
//

import SwiftUI
import MapKit
import Combine

@MainActor
class TripViewModel: ObservableObject {

    // MARK: - Trip data
    @Published var trip: Trip = Trip()
    @Published var tripStarted: Bool = false
    @Published var stops: [PlaceResult] = []

    // MARK: - Map & navigation
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var route: MKRoute?
    @Published var currentLocation: CLLocation?
    @Published var currentStepIndex: Int = 0
    @Published var isCalculatingRoute = false
    @Published var routeError: String?

    // MARK: - Rerouting UI state (NEW)
    @Published var isOffRoute: Bool = false
    @Published var isRerouting: Bool = false

    // MARK: - Turn list
    @Published var showTurnList = false

    // MARK: - Discovery
    @Published var discoveredPlaces: [PlaceResult] = []
    @Published var isSearching = false
    @Published var activeCategory: PlaceCategory?
    @Published var showResults = false

    // MARK: - Services
    let locationService = LocationService()
    private let routeService = RouteService()
    private let placesService = PlacesService()
    private let filterService = FilterService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        // Location updates → currentLocation + step tracking + camera follow
        locationService.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loc in
                guard let self else { return }
                self.currentLocation = loc
                self.updateCurrentStep()
                if self.tripStarted && self.route != nil {
                    self.zoomToCurrentPosition()
                }
            }
            .store(in: &cancellables)

        // Route updates → store + push to LocationService so off-route detection runs
        routeService.$route
            .receive(on: DispatchQueue.main)
            .sink { [weak self] r in
                guard let self else { return }
                self.route = r
                self.locationService.activeRoute = r      // ← NEW: keep LocationService in sync
                if r != nil {
                    self.zoomToStartOfRoute()
                    // After a reroute completes, reset off-route state
                    self.locationService.rerouteCompleted()
                    self.isOffRoute = false
                    self.isRerouting = false
                }
            }
            .store(in: &cancellables)

        routeService.$isCalculating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.isCalculatingRoute = v }
            .store(in: &cancellables)

        routeService.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] e in self?.routeError = e }
            .store(in: &cancellables)

        // Off-route flag from LocationService → publish to UI (NEW)
        locationService.$isOffRoute
            .receive(on: DispatchQueue.main)
            .sink { [weak self] offRoute in
                self?.isOffRoute = offRoute
            }
            .store(in: &cancellables)

        // Rerouting flag from LocationService → publish to UI (NEW)
        locationService.$isRerouting
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rerouting in
                self?.isRerouting = rerouting
            }
            .store(in: &cancellables)

        // Wire the reroute callback: LocationService detects off-route → we ask RouteService (NEW)
        locationService.onRerouteNeeded = { [weak self] currentCoord in
            guard let self,
                  let destination = self.trip.destination else { return }
            Task {
                await self.routeService.reroute(from: currentCoord,
                                                to: destination.coordinate)
            }
        }
    }

    // MARK: - Computed

    var canStartTrip: Bool {
        trip.origin != nil && trip.destination != nil && !trip.passengers.isEmpty
    }

    var currentStep: MKRoute.Step? {
        guard let route, currentStepIndex < route.steps.count else { return nil }
        return route.steps[currentStepIndex]
    }

    var allSteps: [MKRoute.Step] {
        route?.steps.filter { !$0.instructions.isEmpty } ?? []
    }

    var distanceRemaining: String {
        guard let route else { return "" }
        return String(format: "%.0f mi", route.distance / 1609.34)
    }

    var etaString: String {
        guard let route else { return "" }
        let arrival = Date().addingTimeInterval(route.expectedTravelTime)
        let f = DateFormatter(); f.timeStyle = .short
        return f.string(from: arrival)
    }

    var travelTimeString: String {
        guard let route else { return "" }
        let minutes = route.expectedTravelTime / 60
        if minutes < 60 { return String(format: "%.0f min", minutes) }
        let h = Int(minutes / 60), m = Int(minutes) % 60
        return "\(h)h \(m)m"
    }

    // MARK: - Trip actions

    func startTrip() {
        guard let o = trip.origin, let d = trip.destination else { return }
        locationService.requestPermission()
        tripStarted = true
        zoomToCoordinate(o.coordinate, span: 0.02)
        Task { await routeService.calculateRoute(from: o.coordinate, to: d.coordinate) }
    }

    func openTurnByTurnInAppleMaps() {
        guard let o = trip.origin, let d = trip.destination else { return }
        routeService.openInAppleMaps(from: o, to: d)
    }

    // MARK: - Stop management

    func addStop(_ place: PlaceResult) {
        guard !stops.contains(where: { $0.name == place.name }) else { return }
        stops.append(place)
        showResults = false
        if let coord = place.mapItem.placemark.location?.coordinate {
            zoomToCoordinate(coord, span: 0.015)
        }
    }

    func removeStop(_ place: PlaceResult) {
        stops.removeAll { $0.name == place.name }
    }

    func isStop(_ place: PlaceResult) -> Bool {
        stops.contains(where: { $0.name == place.name })
    }

    // MARK: - Discovery

    func findNearby(category: PlaceCategory) {
        let location = currentLocation ?? syntheticLocation()
        guard let location else { return }
        activeCategory = category
        isSearching = true
        discoveredPlaces = []

        Task {
            var raw: [MKMapItem]
            if let route {
                raw = await placesService.searchAlongRoute(category: category, route: route, currentLocation: location)
            } else {
                raw = await placesService.search(category: category, near: location.coordinate)
            }

            let results: [PlaceResult]
            switch category {
            case .food:
                results = filterService.score(places: raw, for: trip.passengers, currentLocation: location, route: route)
            case .gas:
                results = filterService.filterGasStations(items: raw, currentLocation: location, route: route)
            case .restroom:
                var restroomRaw = raw
                if let route {
                    let gasRaw = await placesService.searchAlongRoute(category: .gas, route: route, currentLocation: location)
                    restroomRaw += gasRaw
                } else {
                    let gasRaw = await placesService.search(category: .gas, near: location.coordinate)
                    restroomRaw += gasRaw
                }
                results = filterService.filterRestrooms(items: restroomRaw, currentLocation: location, route: route)
            }

            self.discoveredPlaces = results
            self.isSearching = false
            self.showResults = true
        }
    }

    func addPassenger(_ passenger: Passenger) { trip.passengers.append(passenger) }
    func removePassengers(at offsets: IndexSet) { trip.passengers.remove(atOffsets: offsets) }

    // MARK: - Camera

    func recenterOnRoute() {
        route != nil ? zoomToCurrentPosition() : fitMapToBothPoints()
    }

    private func zoomToCurrentPosition() {
        guard let loc = currentLocation else { return }
        zoomToCoordinate(loc.coordinate, span: 0.008)
    }

    private func zoomToStartOfRoute() {
        guard let origin = trip.origin else { return }
        cameraPosition = .region(MKCoordinateRegion(
            center: origin.coordinate,
            latitudinalMeters: 8000,
            longitudinalMeters: 8000
        ))
    }

    private func zoomToCoordinate(_ coord: CLLocationCoordinate2D, span: Double) {
        cameraPosition = .region(MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        ))
    }

    func fitMapToBothPoints() {
        guard let o = trip.origin, let d = trip.destination else { return }
        let minLat = min(o.coordinate.latitude, d.coordinate.latitude)
        let maxLat = max(o.coordinate.latitude, d.coordinate.latitude)
        let minLon = min(o.coordinate.longitude, d.coordinate.longitude)
        let maxLon = max(o.coordinate.longitude, d.coordinate.longitude)
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: (maxLat - minLat) * 1.5 + 0.05,
                longitudeDelta: (maxLon - minLon) * 1.5 + 0.05
            )
        ))
    }

    // MARK: - Private helpers

    private func updateCurrentStep() {
        guard let location = currentLocation, let steps = route?.steps else { return }
        for (i, step) in steps.enumerated() {
            let stepLoc = CLLocation(
                latitude: step.polyline.coordinate.latitude,
                longitude: step.polyline.coordinate.longitude
            )
            if location.distance(from: stepLoc) < 80 {
                currentStepIndex = i; break
            }
        }
    }

    private func syntheticLocation() -> CLLocation? {
        guard let coord = trip.origin?.coordinate else { return nil }
        return CLLocation(latitude: coord.latitude, longitude: coord.longitude)
    }
}
