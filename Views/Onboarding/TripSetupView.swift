import SwiftUI
import MapKit

struct TripSetupView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @StateObject private var originSearch = AddressSearchService()
    @StateObject private var destSearch = AddressSearchService()

    @State private var originText: String = ""
    @State private var destText: String = ""
    @State private var focusedField: Field? = nil
    @State private var showPassengers = false

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
                            icon: "smallcircle.filled.circle",
                            iconColor: .green,
                            text: $originText,
                            placeholder: "Starting point",
                            isFocused: focusedField == .origin,
                            confirmedName: tripVM.trip.origin?.name,
                            onTap: {
                                if focusedField == .origin {
                                    focusedField = nil
                                } else {
                                    focusedField = .origin
                                    destSearch.cancel()
                                }
                            },
                            onConfirm: {
                                confirmOrigin()
                            }
                        )
                        .onChange(of: originText) { _, newValue in
                            tripVM.trip.origin = nil
                            originSearch.update(query: newValue)
                        }

                        Divider().padding(.leading, 52)

                        AddressField(
                            label: "To",
                            icon: "mappin.circle.fill",
                            iconColor: .red,
                            text: $destText,
                            placeholder: "Destination",
                            isFocused: focusedField == .destination,
                            confirmedName: tripVM.trip.destination?.name,
                            onTap: {
                                if focusedField == .destination {
                                    focusedField = nil
                                } else {
                                    focusedField = .destination
                                    originSearch.cancel()
                                }
                            },
                            onConfirm: {
                                confirmDestination()
                            }
                        )
                        .onChange(of: destText) { _, newValue in
                            tripVM.trip.destination = nil
                            destSearch.update(query: newValue)
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // ── Origin suggestions ─────────────────────────────────
                    if focusedField == .origin && !originSearch.suggestions.isEmpty {
                        SuggestionList(suggestions: originSearch.suggestions) { item in
                            tripVM.trip.origin = SavedLocation(
                                name: item.name ?? item.placemark.title ?? "Unknown",
                                coordinate: item.placemark.coordinate
                            )
                            originText = item.name ?? ""
                            focusedField = nil
                            originSearch.cancel()
                        }
                    }

                    // ── Destination suggestions ────────────────────────────
                    if focusedField == .destination && !destSearch.suggestions.isEmpty {
                        SuggestionList(suggestions: destSearch.suggestions) { item in
                            tripVM.trip.destination = SavedLocation(
                                name: item.name ?? item.placemark.title ?? "Unknown",
                                coordinate: item.placemark.coordinate
                            )
                            destText = item.name ?? ""
                            focusedField = nil
                            destSearch.cancel()
                        }
                    }

                    // ── Passengers card ────────────────────────────────────
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

                    // ── Validation hints ───────────────────────────────────
                    if !tripVM.trip.passengers.isEmpty ||
                        tripVM.trip.origin != nil ||
                        tripVM.trip.destination != nil {
                        VStack(spacing: 6) {
                            ValidationRow(done: tripVM.trip.origin != nil,       label: "Starting point set")
                            ValidationRow(done: tripVM.trip.destination != nil,  label: "Destination set")
                            ValidationRow(done: !tripVM.trip.passengers.isEmpty, label: "At least one passenger added")
                        }
                        .padding(.horizontal)
                    }

                    // ── Let's Go button ────────────────────────────────────
                    Button {
                        focusedField = nil
                        tripVM.startTrip()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Let's Go!")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(tripVM.canStartTrip ? Color.blue : Color.gray.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!tripVM.canStartTrip)
                    .padding(.horizontal)

                    if let err = tripVM.routeError {
                        Text("⚠️ \(err)")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    Spacer().frame(height: 16)
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

    // MARK: - Confirm helpers

    private func confirmOrigin() {
        guard !originText.isEmpty else { return }
        // If suggestions are already loaded, just use the first one
        if let first = originSearch.suggestions.first {
            tripVM.trip.origin = SavedLocation(
                name: first.name ?? originText,
                coordinate: first.placemark.coordinate
            )
            originText = first.name ?? originText
            focusedField = nil
            originSearch.cancel()
            return
        }
        // Otherwise fire a fresh search
        focusedField = nil
        originSearch.cancel()
        Task {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = originText
            request.resultTypes = [.address, .pointOfInterest]
            if let response = try? await MKLocalSearch(request: request).start(),
               let first = response.mapItems.first {
                tripVM.trip.origin = SavedLocation(
                    name: first.name ?? originText,
                    coordinate: first.placemark.coordinate
                )
                originText = first.name ?? originText
            }
        }
    }

    private func confirmDestination() {
        guard !destText.isEmpty else { return }
        if let first = destSearch.suggestions.first {
            tripVM.trip.destination = SavedLocation(
                name: first.name ?? destText,
                coordinate: first.placemark.coordinate
            )
            destText = first.name ?? destText
            focusedField = nil
            destSearch.cancel()
            return
        }
        focusedField = nil
        destSearch.cancel()
        Task {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = destText
            request.resultTypes = [.address, .pointOfInterest]
            if let response = try? await MKLocalSearch(request: request).start(),
               let first = response.mapItems.first {
                tripVM.trip.destination = SavedLocation(
                    name: first.name ?? destText,
                    coordinate: first.placemark.coordinate
                )
                destText = first.name ?? destText
            }
        }
    }
}

// MARK: - AddressField

struct AddressField: View {
    let label: String
    let icon: String
    let iconColor: Color
    @Binding var text: String
    let placeholder: String
    let isFocused: Bool
    let confirmedName: String?
    let onTap: () -> Void
    let onConfirm: () -> Void

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
                        .textInputAutocapitalization(.words)
                        .submitLabel(.search)
                        .onSubmit { onConfirm() }
                }
            }

            Spacer()

            if confirmedName != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if !text.isEmpty {
                Button(action: onConfirm) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(iconColor)
                        .font(.title3)
                }
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

// MARK: - SuggestionList

struct SuggestionList: View {
    let suggestions: [MKMapItem]
    let onSelect: (MKMapItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(suggestions.indices, id: \.self) { i in
                let item = suggestions[i]
                Button {
                    onSelect(item)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name ?? "Unknown")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            if let subtitle = item.placemark.title, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                }
                .buttonStyle(.plain)

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

// MARK: - PassengerChip

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

// MARK: - ValidationRow

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
