//
//  PassengerRosterView.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI

struct PassengerRosterView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAddPassenger = false

    var body: some View {
        NavigationStack {
            List {
                if tripVM.trip.passengers.isEmpty {
                    ContentUnavailableView(
                        "No passengers yet",
                        systemImage: "person.slash",
                        description: Text("Add people so RouteSnack can find the best stops for everyone.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(tripVM.trip.passengers) { p in
                        NavigationLink {
                            PassengerDetailView(passenger: p)
                                .environmentObject(tripVM)
                        } label: {
                            PassengerRow(passenger: p)
                        }
                    }
                    .onDelete { tripVM.removePassengers(at: $0) }
                }
            }
            .navigationTitle("Who's in the Car?")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showAddPassenger = true
                    } label: {
                        Label("Add", systemImage: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showAddPassenger) {
                AddPassengerView()
                    .environmentObject(tripVM)
            }
        }
    }
}

struct PassengerRow: View {
    let passenger: Passenger
    var body: some View {
        HStack(spacing: 12) {
            Text(passenger.emoji)
                .font(.largeTitle)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(passenger.name).font(.headline)
                    if passenger.isDriver {
                        Text("Driver")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
                if !passenger.dietaryProfile.restrictions.isEmpty {
                    Text(passenger.dietaryProfile.restrictions.map(\.displayName).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !passenger.dietaryProfile.allergens.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption2)
                        Text(passenger.dietaryProfile.allergens.map(\.displayName).joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
