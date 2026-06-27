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
            // ── Map ────────────────────────────────────────────────────────
            Map(position: $tripVM.cameraPosition) {
                UserAnnotation()

                if let route = tripVM.route {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 5)
                }

                // Origin pin
                if let origin = tripVM.trip.origin {
                    Annotation(origin.name, coordinate: origin.coordinate) {
                        Image(systemName: "smallcircle.filled.circle")
                            .padding(8)
                            .background(.green)
                            .clipShape(Circle())
                            .foregroundStyle(.white)
                    }
                }

                // Destination pin
                if let dest = tripVM.trip.destination {
                    Annotation(dest.name, coordinate: dest.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .padding(8)
                            .background(.red)
                            .clipShape(Circle())
                            .foregroundStyle(.white)
                    }
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
            .ignoresSafeArea(edges: .top)

            // ── Overlay HUD ────────────────────────────────────────────────
            VStack(spacing: 0) {
                // Top bar: route summary + Apple Maps link
                RouteHeaderView()
                    .environmentObject(tripVM)

                Spacer()

                // Bottom action strip
                MapOverlayView()
                    .environmentObject(tripVM)
            }
        }
        .sheet(isPresented: $tripVM.showResults) {
            PlaceResultsSheet()
                .environmentObject(tripVM)
        }
    }
}

struct PlacePinView: View {
    let place: PlaceResult
    var body: some View {
        Image(systemName: place.category.icon)
            .padding(8)
            .background(pinColor)
            .clipShape(Circle())
            .foregroundStyle(.white)
            .shadow(radius: 3)
    }
    var pinColor: Color {
        switch place.category {
        case .food:     return .orange
        case .gas:      return .green
        case .restroom: return .blue
        }
    }
}
