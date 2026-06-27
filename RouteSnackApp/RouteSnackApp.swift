//
//  MegaRoadTripAppApp.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI

@main
struct RouteSnackApp: App {
    @StateObject private var tripVM = TripViewModel()

    var body: some Scene {
        WindowGroup {
            ContentRouter()
                .environmentObject(tripVM)
        }
    }
}

struct ContentRouter: View {
    @EnvironmentObject var tripVM: TripViewModel

    var body: some View {
        if tripVM.tripStarted {
            MapContainerView()
        } else {
            TripSetupView()
        }
    }
}
