//
//  PlaceCardView.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI

struct PlaceCardView: View {
    let place: PlaceResult
    let onNavigate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.headline)
                    Text(String(format: "%.1f mi away", place.distanceMiles))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // Compatibility badge (food only)
                if place.category == .food {
                    CompatibilityBadge(score: place.compatibilityScore)
                }
            }

            // Compatibility notes
            if !place.compatibilityNotes.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text(place.compatibilityNotes.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Warnings
            if !place.warnings.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text(place.warnings.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            // Navigate button
            Button(action: onNavigate) {
                Label("Navigate", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(.secondary.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CompatibilityBadge: View {
    let score: Double
    var color: Color { score > 0.7 ? .green : score > 0.4 ? .orange : .red }
    var label: String { score > 0.7 ? "Great fit" : score > 0.4 ? "Okay" : "Poor fit" }

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

