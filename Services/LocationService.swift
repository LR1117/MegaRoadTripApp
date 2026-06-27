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

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 50   // update every 50 m
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        #if os(macOS)
        // On macOS, use .authorized as the available case
        if manager.authorizationStatus == .authorized {
            startTracking()
        }
        #else
        // On iOS/iPadOS/watchOS/tvOS, consider both when-in-use and always
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            startTracking()
        }
        #endif
    }
}
