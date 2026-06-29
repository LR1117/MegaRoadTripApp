//
//  LocationService.swift
//  MegaRoadTripApp
//

import CoreLocation
import MapKit
import Combine

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    // MARK: - Published state (existing)
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?

    // MARK: - New: Navigation state
    @Published var currentHeading: CLHeading?
    @Published var isOffRoute: Bool = false
    @Published var isRerouting: Bool = false

    // MARK: - Active route tracking (set by TripViewModel)
    var activeRoute: MKRoute?

    // MARK: - Off-route config
    /// Meters off the polyline before flagging as off-route
    private let offRouteThreshold: Double = 60.0
    /// How many consecutive bad readings before actually rerouting (avoids GPS jitter)
    private let offRouteConfirmCount: Int = 3
    /// Minimum speed (m/s ~= 3 mph) — don't reroute when parked
    private let minimumMovingSpeed: Double = 1.4
    /// Seconds to wait between reroute attempts
    private let rerouteCooldown: TimeInterval = 12.0

    private var offRouteCounter: Int = 0
    private var lastRerouteTime: Date?

    // MARK: - Reroute callback → wired up in TripViewModel
    var onRerouteNeeded: ((CLLocationCoordinate2D) -> Void)?

    // MARK: - Init
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5                          // update every 5 m while navigating
        manager.activityType = .automotiveNavigation
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
    }

    // MARK: - Public API
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        clearNavigationState()
    }

    func clearNavigationState() {
        activeRoute = nil
        isOffRoute = false
        isRerouting = false
        offRouteCounter = 0
        lastRerouteTime = nil
    }

    // Called by TripViewModel when reroute completes so we reset state
    func rerouteCompleted() {
        isRerouting = false
        isOffRoute = false
        offRouteCounter = 0
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // Discard inaccurate readings (GPS noise)
        guard location.horizontalAccuracy > 0, location.horizontalAccuracy < 65 else { return }
        currentLocation = location
        checkIfOffRoute(location: location)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        currentHeading = newHeading
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startTracking()
        case .denied, .restricted:
            locationError = "Location access denied. Please enable it in Settings."
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
    }

    // MARK: - Off-Route Detection

    private func checkIfOffRoute(location: CLLocation) {
        guard let route = activeRoute, !isRerouting else { return }

        // Don't reroute if barely moving (e.g., stopped at lights / parked)
        if location.speed >= 0 && location.speed < minimumMovingSpeed {
            offRouteCounter = 0
            return
        }

        let distanceFromRoute = minimumDistanceToPolyline(from: location, polyline: route.polyline)

        if distanceFromRoute > offRouteThreshold {
            offRouteCounter += 1
            if offRouteCounter >= offRouteConfirmCount {
                DispatchQueue.main.async { self.isOffRoute = true }
                triggerRerouteIfReady(from: location)
            }
        } else {
            offRouteCounter = 0
            DispatchQueue.main.async { self.isOffRoute = false }
        }
    }

    private func triggerRerouteIfReady(from location: CLLocation) {
        // Cooldown: don't spam reroute requests
        if let last = lastRerouteTime, Date().timeIntervalSince(last) < rerouteCooldown { return }
        lastRerouteTime = Date()
        DispatchQueue.main.async {
            self.isRerouting = true
            self.onRerouteNeeded?(location.coordinate)
        }
    }

    // MARK: - Geometry: Point-to-Polyline Distance

    /// Returns the minimum distance in meters from `location` to any segment of `polyline`
    private func minimumDistanceToPolyline(from location: CLLocation, polyline: MKPolyline) -> Double {
        let pointCount = polyline.pointCount
        guard pointCount > 0 else { return .greatestFiniteMagnitude }

        let points = polyline.points()
        let px = MKMapPoint(location.coordinate)
        var minDist = Double.greatestFiniteMagnitude

        for i in 0..<(pointCount - 1) {
            let a = points[i]
            let b = points[i + 1]
            let d = pointToSegmentMeters(p: px, a: a, b: b)
            if d < minDist { minDist = d }
        }
        return minDist
    }

    private func pointToSegmentMeters(p: MKMapPoint, a: MKMapPoint, b: MKMapPoint) -> Double {
        let dx = b.x - a.x, dy = b.y - a.y
        if dx == 0 && dy == 0 {
            return p.distance(to: a)
        }
        let t = max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / (dx * dx + dy * dy)))
        let closest = MKMapPoint(x: a.x + t * dx, y: a.y + t * dy)
        // MKMapPoint.distance returns meters
        return p.distance(to: closest)
    }
}
