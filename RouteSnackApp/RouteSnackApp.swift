//
//  MegaRoadTripAppApp.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI
import Combine

@main
struct RouteSnackApp: App {
    @StateObject private var tripVM = TripViewModel()
    @State private var tripConfigured = false

    var body: some Scene {
        WindowGroup {
            if tripConfigured {
                MapContainerView()
                    .environmentObject(tripVM)
            } else {
                TripSetupView()
                    .environmentObject(tripVM)
                    .onReceive(tripVM.$route.compactMap { $0 }) { _ in
                        tripConfigured = true
                    }
            }
        }
    }
}
