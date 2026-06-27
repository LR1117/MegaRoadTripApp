//
//  MapContainerView.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI
import MapKit

struct MapContainerView: View {
    @EnvironmentObject var tripVM: TripViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $tripVM.cameraPosition) {
                // User location puck
                UserAnnotation()

                // Route polyline
                if let route = tripVM.route {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 5)
                }

                // Discovered place pins
                ForEach(tripVM.discoveredPlaces) { place in
                    if let coord = place.mapItem.placemark.location?.coordinate {
                        Annotation(place.name, coordinate: coord) {
                            PlacePinView(place: place)
                        }
                    }
                }
            }
            .mapControls {
                MapCompass()
                MapUserLocationButton()
                MapScaleView()
            }

            // HUD overlay buttons
            MapOverlayView()
                .environmentObject(tripVM)
        }
        .sheet(isPresented: $tripVM.showResults) {
            PlaceResultsSheet()
                .environmentObject(tripVM)
        }
    }
}

// Small coloured pin
struct PlacePinView: View {
    let place: PlaceResult
    var body: some View {
        Image(systemName: iconName)
            .padding(8)
            .background(iconColor)
            .clipShape(Circle())
            .foregroundStyle(.white)
    }
    var iconName: String {
        switch place.category {
        case .food:     return "fork.knife"
        case .gas:      return "fuelpump.fill"
        case .restroom: return "toilet.fill"
        }
    }
    var iconColor: Color {
        switch place.category {
        case .food:     return .orange
        case .gas:      return .green
        case .restroom: return .blue
        }
    }
}
