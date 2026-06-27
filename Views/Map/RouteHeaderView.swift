//
//  RouteHeaderView.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/27/26.
//


import SwiftUI
import MapKit

struct RouteHeaderView: View {
    @EnvironmentObject var tripVM: TripViewModel

    var distanceString: String {
        guard let route = tripVM.route else { return "—" }
        let miles = route.distance / 1609.34
        return String(format: "%.0f mi", miles)
    }

    var etaString: String {
        guard let route = tripVM.route else { return "—" }
        let minutes = route.expectedTravelTime / 60
        if minutes < 60 {
            return String(format: "%.0f min", minutes)
        } else {
            let h = Int(minutes / 60)
            let m = Int(minutes) % 60
            return "\(h)h \(m)m"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                if let dest = tripVM.trip.destination {
                    Text("To \(dest.name)")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    Label(distanceString, systemImage: "road.lanes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label(etaString, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                tripVM.openTurnByTurnInAppleMaps()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    Text("Turn-by-Turn")
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thinMaterial)
    }
}