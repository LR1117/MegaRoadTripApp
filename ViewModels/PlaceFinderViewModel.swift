//
//  PlaceFinderViewModel.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI
import MapKit
import Combine

// Thin VM used by the results sheet to open navigation
class PlaceFinderViewModel: ObservableObject {
    @MainActor
    init() {}
    
    func openInMaps(_ result: PlaceResult) {
        result.mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
