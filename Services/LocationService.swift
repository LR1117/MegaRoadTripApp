//
//  LocationService.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 50
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
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
}
