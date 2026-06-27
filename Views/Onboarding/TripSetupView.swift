//
//  TripSetupView.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI
import MapKit

struct TripSetupView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @StateObject private var originSearch  = AddressSearchService()
    @StateObject private var destSearch    = AddressSearchService()

    @State private var originText:  String = ""
    @State private var destText:    String = ""
    @State private var focusedField: Field? = nil
    @State private var showPassengers = false
    @State private var isResolvingOrigin = false
    @State private var isResolvingDest   = false

    enum Field { case origin, destination }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ── App header ─────────────────────────────────────────
                    VStack(spacing: 4) {
                        Text("🚗")
                            .font(.system(size: 56))
                        Text("RouteSnack")
                            .font(.largeTitle.bold())
                        Text("Road trips, fed right.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // ── Route card ─────────────────────────────────────────
                    VStack(spacing: 0) {
                        AddressField(
                            label: "From",
                            icon:  "smallcircle.filled.circle",
                            iconColor: .green,
                            text: $originText,
                            placeholder: "Starting point",
                            isFocused: focusedField == .origin,
                            isLoading: isResolvingOrigin,
                            confirmedName: tripVM.trip.origin?.name
                        ) {
                            focusedField = (focusedField == .origin) ? nil : .origin
                            if focusedField == .origin { destSearch.cancel() }
                        }
                        .onChange(of: originText) { _, new in
                            tripVM.trip.origin = nil
                            originSearch.update(query: new)
                        }

                        Divider().padding(.leading, 52)

                        AddressField(
                            label: "To",
                            icon:  "mappin.circle.fill",
                            iconColor: .red,
                            text: $destText,
                            placeholder: "Destination",
                            isFocused: focusedField == .destination,
                            isLoading: isResolvingDest,
                            confirmedName: tripVM.trip.destination?.name
                        ) {
                            focusedField = (focusedField == .destination) ? nil : .destination
                            if focusedField == .destination { originSearch.cancel() }
                        }
                        .onChange(of: destText) { _, new in
                            tripVM.trip.destination = nil
                            destSearch.update(query: new)
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // ── Suggestions dropdown ───────────────────────────────
                    if focusedField == .origin && !originSearch.suggestions.isEmpty {
                        SuggestionList(suggestions: originSearch.suggestions) { pick in
                            isResolvingOrigin = true
                            focusedField = nil
                            originSearch.cancel()
                            Task {
                                if let item = await originSearch.resolve(pick) {
                                    tripVM.trip.origin = SavedLocation(
                                        name: pick.title,
                                        coordinate: item.placemark.coordinate
                                    )
                                    originText = pick.title
                                }
                                isResolvingOrigin = false
                            }
                        }
                    }

                    if focusedField == .destination && !destSearch.suggestions.isEmpty {
                        SuggestionList(suggestions: destSearch.suggestions) { pick in
                            isResolvingDest = true
                            focusedField = nil
                            destSearch.cancel()
                            Task {
                                if let item = await destSearch.resolve(pick) {
                                    tripVM.trip.destination = SavedLocation(
                                        name: pick.title,
                                        coordinate: item.placemark.coordinate
                                    )
                                    destText = pick.title
                                }
                                isResolvingDest = false
                            }
                        }
                    }

                    // ── Passengers card ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Who's in the car?", systemImage: "person.2.fill")
                                .font(.headline)
                            Spacer()
                            Button {
                                showPassengers = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            }
                        }

                        if tripVM.trip.passengers.isEmpty {
                            Text("Add at least one passenger to personalise food stops.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(tripVM.trip.passengers) { p in
                                        PassengerChip(passenger: p)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // ── Validation hints ──────────────────────────────────
                    if !tripVM.trip.passengers.isEmpty || tripVM.trip.origin != nil || tripVM.trip.destination != nil {
                        VStack(spacing: 6) {
                            ValidationRow(done: tripVM.trip.origin != nil,      label: "Starting point set")
                            ValidationRow(done: tripVM.trip.destination != nil, label: "Destination set")
                            ValidationRow(done: !tripVM.trip.passengers.isEmpty, label: "At least one passenger added")
                        }
                        .padding(.horizontal)
                    }

                    // ── Let's Go button ───────────────────────────────────
                    Button(action: {
                        focusedField = nil
                        tripVM.startTrip()
                    }) {
                        HStack {
                            if tripVM.isCalculatingRoute {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            Text(tripVM.isCalculatingRoute ? "Getting route…" : "Let's Go!")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(tripVM.canStartTrip ? Color.blue : Color.gray.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!tripVM.canStartTrip || tripVM.isCalculatingRoute)
                    .padding(.horizontal)
                    .padding(.bottom, 32)

                    if let err = tripVM.routeError {
                        Text("⚠️ \(err)")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .onTapGesture { focusedField = nil }
            .sheet(isPresented: $showPassengers) {
                PassengerRosterView()
                    .environmentObject(tripVM)
            }
        }
    }
}

// MARK: – Sub-views

struct AddressField: View {
    let label: String
    let icon: String
    let iconColor: Color
    @Binding var text: String
    let placeholder: String
    let isFocused: Bool
    let isLoading: Bool
    let confirmedName: String?
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                if let confirmed = confirmedName {
                    Text(confirmed)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.subheadline)
                        .autocorrectionDisabled()
                }
            }

            Spacer()

            if isLoading {
                ProgressView().scaleEffect(0.8)
            } else if confirmedName != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .background(isFocused ? Color.blue.opacity(0.05) : Color.clear)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

struct SuggestionList: View {
    let suggestions: [MKLocalSearchCompletion]
    let onSelect: (MKLocalSearchCompletion) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(suggestions.indices, id: \.self) { i in
                let s = suggestions[i]
                Button {
                    onSelect(s)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(s.title)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            if !s.subtitle.isEmpty {
                                Text(s.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                }

                if i < suggestions.count - 1 {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

struct PassengerChip: View {
    let passenger: Passenger
    var body: some View {
        HStack(spacing: 6) {
            Text(passenger.emoji)
            Text(passenger.name)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundStyle(.blue)
        .clipShape(Capsule())
    }
}

struct ValidationRow: View {
    let done: Bool
    let label: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? .green : .secondary)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(done ? .primary : .secondary)
            Spacer()
        }
    }
}
