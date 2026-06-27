//
//  MegaRoadTripApp.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI

struct AllergenBadgeView: View {
    let allergen: Allergen

    var body: some View {
        HStack(spacing: 4) {
            Text(allergen.icon)
                .font(.caption)
            Text(allergen.displayName)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.12))
        .foregroundStyle(.orange)
        .clipShape(Capsule())
    }
}
