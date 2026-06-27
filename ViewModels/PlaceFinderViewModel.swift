//
//  PlaceFinderViewModel.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI
import MapKit
import Combine
import UIKit
 

class PlaceFinderViewModel: ObservableObject {
    func openInMaps(_ result: PlaceResult) {
        result.mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    func callPlace(_ result: PlaceResult) {
        guard let phone = result.phoneNumber,
              let url = URL(string: "tel://\(phone.filter { $0.isNumber })") else { return }
        UIApplication.shared.open(url)
    }
}
