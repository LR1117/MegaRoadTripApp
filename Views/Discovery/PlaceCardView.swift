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
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ── Header ─────────────────────────────────────────────────────
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.headline)
                    Text(String(format: "%.1f mi away", place.distanceMiles))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !place.address.isEmpty {
                        Text(place.address)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if place.category == .food {
                    CompatibilityBadge(score: place.compatibilityScore)
                }
            }

            // ── Compatibility notes ────────────────────────────────────────
            if !place.compatibilityNotes.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(place.compatibilityNotes, id: \.self) { note in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(note).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // ── Warnings ───────────────────────────────────────────────────
            if !place.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(place.warnings, id: \.self) { w in
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text(w).font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
            }

            // ── Actions ────────────────────────────────────────────────────
            Button(action: onNavigate) {
                Label("Navigate in Apple Maps", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    .frame(maxWidth: .infinity)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(Color(.secondary.opacity(0.75)))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CompatibilityBadge: View {
    let score: Double
    var color: Color  { score > 0.7 ? .green : score > 0.4 ? .orange : .red }
    var label: String { score > 0.7 ? "Great fit" : score > 0.4 ? "Okay" : "Poor fit" }
    var icon: String  { score > 0.7 ? "star.fill"  : score > 0.4 ? "hand.thumbsup" : "exclamationmark" }

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.caption)
            Text(label).font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(color.opacity(0.12))
        .foregroundStyle(color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
