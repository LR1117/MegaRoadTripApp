//
//  PassengerAvatarView.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI

struct PassengerAvatarView: View {
    let passenger: Passenger
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: size, height: size)
            Text(passenger.emoji)
                .font(.system(size: size * 0.55))
        }
    }
}
