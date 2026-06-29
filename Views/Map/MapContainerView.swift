import SwiftUI
import MapKit

// MARK: - MapContainerView

struct MapContainerView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @State private var mapStyle: MapStyle = .standard(
        elevation: .realistic,
        emphasis: .muted,
        pointsOfInterest: .all,
        showsTraffic: true
    )

    var body: some View {
        ZStack {
            // ── Map ──────────────────────────────────────────────────────
            Map(position: $tripVM.cameraPosition) {
                UserAnnotation()

                if let route = tripVM.route {
                    // Outline
                    MapPolyline(route.polyline)
                        .stroke(
                            Color(hex: "1C5BD6").opacity(0.5),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                        )
                    // Main line
                    MapPolyline(route.polyline)
                        .stroke(
                            Color(hex: "3478F6"),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
                        )
                }

                if let origin = tripVM.trip.origin {
                    Annotation("", coordinate: origin.coordinate) {
                        OriginPinView(name: origin.name)
                    }
                }

                if let dest = tripVM.trip.destination {
                    Annotation("", coordinate: dest.coordinate) {
                        DestinationPinView(name: dest.name)
                    }
                }

                // Added stops
                ForEach(tripVM.stops) { stop in
                    if let coord = stop.mapItem.placemark.location?.coordinate {
                        Annotation("", coordinate: coord) {
                            StopPinView(stop: stop)
                        }
                    }
                }

                // Discovered nearby places
                ForEach(tripVM.discoveredPlaces) { place in
                    if let coord = place.mapItem.placemark.location?.coordinate {
                        Annotation("", coordinate: coord) {
                            NearbyPlacePinView(place: place)
                        }
                    }
                }
            }
            .mapStyle(mapStyle)
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea()

            // ── Navigation overlay ───────────────────────────────────────
            VStack(spacing: 0) {
                // Tappable turn banner
                if tripVM.route != nil {
                    Button {
                        if !tripVM.isRerouting && !tripVM.isOffRoute {
                            tripVM.showTurnList = true
                        }
                    } label: {
                        TurnBannerView()
                            .environmentObject(tripVM)
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                VStack(spacing: 10) {
                    // Stops bar (shown when stops exist)
                    if !tripVM.stops.isEmpty {
                        StopsBar()
                            .environmentObject(tripVM)
                    }

                    if tripVM.route != nil {
                        ETABarView()
                            .environmentObject(tripVM)
                    }

                    TripActionBar()
                        .environmentObject(tripVM)
                }
                .padding(.bottom, 36)
            }

            // ── Recenter button ──────────────────────────────────────────
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        withAnimation { tripVM.recenterOnRoute() }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(hex: "3478F6"))
                            .frame(width: 48, height: 48)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 230)
                }
            }
        }
        // Turn list sheet
        .sheet(isPresented: $tripVM.showTurnList) {
            TurnListSheet()
                .environmentObject(tripVM)
        }
        // Nearby results sheet
        .sheet(isPresented: $tripVM.showResults) {
            NearbyResultsSheet()
                .environmentObject(tripVM)
        }
        .animation(.easeInOut(duration: 0.3), value: tripVM.route != nil)
    }
}

// MARK: - Turn Banner (tappable)

struct TurnBannerView: View {
    @EnvironmentObject var tripVM: TripViewModel

    var stepInstruction: String {
        tripVM.currentStep?.instructions
            ?? "Head toward \(tripVM.trip.destination?.name ?? "destination")"
    }

    var stepDistance: String {
        guard let step = tripVM.currentStep else { return "" }
        let miles = step.distance / 1609.34
        if miles < 0.1 { return String(format: "%.0f ft", step.distance * 3.281) }
        return String(format: "%.1f mi", miles)
    }

    var turnIcon: String {
        let i = tripVM.currentStep?.instructions.lowercased() ?? ""
        if i.contains("left")                        { return "arrow.turn.up.left" }
        if i.contains("right")                       { return "arrow.turn.up.right" }
        if i.contains("u-turn")                      { return "arrow.uturn.left" }
        if i.contains("merge")                       { return "arrow.merge" }
        if i.contains("ramp") || i.contains("exit") { return "arrow.turn.down.right" }
        if i.contains("roundabout")                  { return "arrow.clockwise" }
        if i.contains("arrive") || i.contains("destination") { return "mappin.circle.fill" }
        return "arrow.up"
    }

    var body: some View {
        Group {
            if tripVM.isRerouting {
                // ── Rerouting banner ──────────────────────────────────────
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "8E44AD"))
                            .frame(width: 52, height: 52)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rerouting…")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("Calculating a new route")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .padding(.horizontal, 12)
                .padding(.top, 56)

            } else if tripVM.isOffRoute {
                // ── Off-route banner ──────────────────────────────────────
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "FF9500"))
                            .frame(width: 52, height: 52)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Off Route")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("Finding a new route…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(hex: "FF9500").opacity(0.3), radius: 8, y: 4)
                .padding(.horizontal, 12)
                .padding(.top, 56)

            } else {
                // ── Normal turn banner ────────────────────────────────────
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "3478F6"))
                            .frame(width: 52, height: 52)
                        Image(systemName: turnIcon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        if !stepDistance.isEmpty {
                            Text(stepDistance)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(hex: "3478F6"))
                        }
                        Text(stepInstruction)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .padding(.horizontal, 12)
                .padding(.top, 56)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: tripVM.isOffRoute)
        .animation(.easeInOut(duration: 0.25), value: tripVM.isRerouting)
    }
}


// MARK: - Turn List Sheet

struct TurnListSheet: View {
    @EnvironmentObject var tripVM: TripViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if tripVM.allSteps.isEmpty {
                    Text("No turn information available.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(tripVM.allSteps.enumerated()), id: \.offset) { index, step in
                        HStack(spacing: 14) {
                            // Step icon
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(index == tripVM.currentStepIndex
                                          ? Color(hex: "3478F6")
                                          : Color(hex: "3478F6").opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: iconFor(step: step))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(index == tripVM.currentStepIndex
                                                     ? .white
                                                     : Color(hex: "3478F6"))
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(step.instructions)
                                    .font(.subheadline.weight(index == tripVM.currentStepIndex ? .bold : .regular))
                                    .foregroundStyle(.primary)

                                let miles = step.distance / 1609.34
                                let distStr = miles < 0.1
                                    ? String(format: "%.0f ft", step.distance * 3.281)
                                    : String(format: "%.1f mi", miles)
                                Text(distStr)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if index == tripVM.currentStepIndex {
                                Text("NOW")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: "3478F6"))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(
                            index == tripVM.currentStepIndex
                                ? Color(hex: "3478F6").opacity(0.06)
                                : Color.clear
                        )
                    }

                    // Destination row
                    if let dest = tripVM.trip.destination {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "FF3B30").opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color(hex: "FF3B30"))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Arrive at \(dest.name)")
                                    .font(.subheadline.weight(.semibold))
                                Text(tripVM.distanceRemaining + " · " + tripVM.travelTimeString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Turn-by-Turn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func iconFor(step: MKRoute.Step) -> String {
        let i = step.instructions.lowercased()
        if i.contains("left")                        { return "arrow.turn.up.left" }
        if i.contains("right")                       { return "arrow.turn.up.right" }
        if i.contains("u-turn")                      { return "arrow.uturn.left" }
        if i.contains("merge")                       { return "arrow.merge" }
        if i.contains("ramp") || i.contains("exit") { return "arrow.turn.down.right" }
        if i.contains("roundabout")                  { return "arrow.clockwise" }
        if i.contains("arrive")                      { return "mappin.circle.fill" }
        return "arrow.up"
    }
}

// MARK: - ETA Bar

struct ETABarView: View {
    @EnvironmentObject var tripVM: TripViewModel

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                Text(tripVM.travelTimeString)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("travel time")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 32)

            VStack(spacing: 2) {
                Text(tripVM.distanceRemaining)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("distance")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 32)

            VStack(spacing: 2) {
                Text(tripVM.etaString)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("arrival")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
        .padding(.horizontal, 12)
    }
}

// MARK: - Stops Bar

struct StopsBar: View {
    @EnvironmentObject var tripVM: TripViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Color(hex: "3478F6"))
                    .font(.caption.weight(.semibold))
                Text("Added Stops")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tripVM.stops) { stop in
                        HStack(spacing: 6) {
                            Image(systemName: stop.category.icon)
                                .font(.caption)
                                .foregroundStyle(stopColor(stop))
                            Text(stop.name)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                            Button {
                                tripVM.removeStop(stop)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(stopColor(stop).opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .padding(.horizontal, 12)
    }

    private func stopColor(_ stop: PlaceResult) -> Color {
        switch stop.category {
        case .food:     return Color(hex: "FF9500")
        case .gas:      return Color(hex: "30D158")
        case .restroom: return Color(hex: "3478F6")
        }
    }
}

// MARK: - Action Bar

struct TripActionBar: View {
    @EnvironmentObject var tripVM: TripViewModel

    var body: some View {
        HStack(spacing: 10) {
            ActionButton(label: "Food",      icon: "fork.knife",    color: Color(hex: "FF9500")) {
                tripVM.findNearby(category: .food)
            }
            ActionButton(label: "Gas",       icon: "fuelpump.fill", color: Color(hex: "30D158")) {
                tripVM.findNearby(category: .gas)
            }
            ActionButton(label: "Rest Stop", icon: "toilet.fill",   color: Color(hex: "3478F6")) {
                tripVM.findNearby(category: .restroom)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, 12)
    }
}

struct ActionButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Nearby Results Sheet

struct NearbyResultsSheet: View {
    @EnvironmentObject var tripVM: TripViewModel

    var title: String {
        switch tripVM.activeCategory {
        case .food:     return "Food Near You"
        case .gas:      return "Gas Stations"
        case .restroom: return "Rest Stops"
        case nil:       return "Nearby"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if tripVM.isSearching {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Finding the best options…")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if tripVM.discoveredPlaces.isEmpty {
                    ContentUnavailableView(
                        "Nothing Found",
                        systemImage: "mappin.slash",
                        description: Text("Try searching in a different area.")
                    )

                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if tripVM.activeCategory == .food {
                                NearbyGroupBanner(passengers: tripVM.trip.passengers)
                                    .padding(.horizontal)
                            }
                            ForEach(tripVM.discoveredPlaces) { place in
                                NearbyPlaceCard(place: place)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { tripVM.showResults = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Group Banner

struct NearbyGroupBanner: View {
    let passengers: [Passenger]

    var allAllergens: [Allergen] {
        Array(Set(passengers.flatMap { Array($0.dietaryProfile.allergens) }))
    }
    var allRestrictions: [DietaryRestriction] {
        Array(Set(passengers.flatMap { Array($0.dietaryProfile.restrictions) }))
    }

    var body: some View {
        if allAllergens.isEmpty && allRestrictions.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Filtered for your group")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(allRestrictions, id: \.self) { r in
                            Text("\(r.icon) \(r.displayName)")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.green.opacity(0.12))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                        ForEach(allAllergens, id: \.self) { a in
                            Text("⚠️ No \(a.displayName)")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.orange.opacity(0.12))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Place Card (Add Stop instead of Navigate)

struct NearbyPlaceCard: View {
    @EnvironmentObject var tripVM: TripViewModel
    let place: PlaceResult
    @State private var added = false

    var isAlreadyAdded: Bool { tripVM.isStop(place) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.headline)
                    Text(String(format: "%.1f mi away", place.distanceMiles))
                        .font(.caption).foregroundStyle(.secondary)
                    if !place.address.isEmpty {
                        Text(place.address)
                            .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer()
                if place.category == .food {
                    NearbyCompatibilityBadge(score: place.compatibilityScore)
                }
            }

            if !place.compatibilityNotes.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(place.compatibilityNotes, id: \.self) { note in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green).font(.caption)
                            Text(note).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !place.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(place.warnings, id: \.self) { w in
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange).font(.caption)
                            Text(w).font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
            }

            // Add Stop button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    if isAlreadyAdded {
                        tripVM.removeStop(place)
                    } else {
                        tripVM.addStop(place)
                        added = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            added = false
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: isAlreadyAdded ? "mappin.circle.fill" : "plus.circle.fill")
                    Text(isAlreadyAdded ? "Stop Added ✓" : "Add as Stop")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .font(.subheadline)
            }
            .buttonStyle(.borderedProminent)
            .tint(isAlreadyAdded ? Color(hex: "30D158") : Color(hex: "3478F6"))
            .animation(.easeInOut, value: isAlreadyAdded)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isAlreadyAdded ? Color(hex: "30D158").opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
    }
}

struct NearbyCompatibilityBadge: View {
    let score: Double
    var color: Color  { score > 0.7 ? Color(hex: "30D158") : score > 0.4 ? Color(hex: "FF9500") : Color(hex: "FF3B30") }
    var label: String { score > 0.7 ? "Great fit" : score > 0.4 ? "Okay" : "Poor fit" }
    var icon: String  { score > 0.7 ? "star.fill" : score > 0.4 ? "hand.thumbsup" : "exclamationmark" }

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

// MARK: - Pin Views

struct OriginPinView: View {
    let name: String
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().fill(.white).frame(width: 28, height: 28).shadow(radius: 3)
                Circle().fill(Color(hex: "30D158")).frame(width: 20, height: 20)
            }
            Text(name)
                .font(.caption2.weight(.semibold)).foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color(hex: "30D158")).clipShape(Capsule()).shadow(radius: 2)
        }
    }
}

struct DestinationPinView: View {
    let name: String
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().fill(Color(hex: "FF3B30")).frame(width: 36, height: 36)
                    .shadow(color: Color(hex: "FF3B30").opacity(0.4), radius: 6)
                Image(systemName: "mappin").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
            }
            Text(name)
                .font(.caption2.weight(.semibold)).foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color(hex: "FF3B30")).clipShape(Capsule()).shadow(radius: 2)
        }
    }
}

struct StopPinView: View {
    let stop: PlaceResult

    var pinColor: Color {
        switch stop.category {
        case .food:     return Color(hex: "FF9500")
        case .gas:      return Color(hex: "30D158")
        case .restroom: return Color(hex: "3478F6")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().fill(.white).frame(width: 36, height: 36).shadow(radius: 3)
                Circle().fill(pinColor.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: stop.category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(pinColor)
            }
            Text(stop.name)
                .font(.caption2.weight(.semibold)).foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(pinColor).clipShape(Capsule()).shadow(radius: 2)
        }
    }
}

struct NearbyPlacePinView: View {
    let place: PlaceResult

    var pinColor: Color {
        switch place.category {
        case .food:     return Color(hex: "FF9500")
        case .gas:      return Color(hex: "30D158")
        case .restroom: return Color(hex: "3478F6")
        }
    }

    var body: some View {
        ZStack {
            Circle().fill(.white).frame(width: 40, height: 40).shadow(color: .black.opacity(0.2), radius: 4)
            Circle().fill(pinColor.opacity(0.15)).frame(width: 36, height: 36)
            Image(systemName: place.category.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(pinColor)
        }
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
