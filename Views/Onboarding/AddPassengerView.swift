//
//  AddPassengerView'.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import SwiftUI

struct AddPassengerView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @StateObject private var vm = PassengerViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // ── Identity ───────────────────────────────────────────────
                Section("Name & Avatar") {
                    TextField("Passenger name", text: $vm.name)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose an avatar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(vm.emojiOptions, id: \.self) { e in
                                    Text(e)
                                        .font(.system(size: 32))
                                        .padding(8)
                                        .background(
                                            vm.emoji == e
                                            ? Color.accentColor.opacity(0.2)
                                            : Color(.tertiarySystemBackground)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(vm.emoji == e ? Color.accentColor : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture { vm.emoji = e }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    Toggle("This person is driving", isOn: $vm.isDriver)
                }

                // ── Dietary restrictions ───────────────────────────────────
                Section {
                    ForEach(DietaryRestriction.allCases) { r in
                        Toggle(isOn: Binding(
                            get: { vm.dietaryProfile.restrictions.contains(r) },
                            set: {
                                if $0 { vm.dietaryProfile.restrictions.insert(r) }
                                else  { vm.dietaryProfile.restrictions.remove(r) }
                            }
                        )) {
                            Label(r.displayName, title: { Text(r.displayName) })
                                .badge(r.icon)
                        }
                    }
                } header: {
                    Text("Dietary Restrictions")
                } footer: {
                    Text("These help RouteSnack prioritise restaurants that suit everyone.")
                }

                // ── Allergens ──────────────────────────────────────────────
                Section {
                    ForEach(Allergen.allCases) { a in
                        Toggle(isOn: Binding(
                            get: { vm.dietaryProfile.allergens.contains(a) },
                            set: {
                                if $0 { vm.dietaryProfile.allergens.insert(a) }
                                else  { vm.dietaryProfile.allergens.remove(a) }
                            }
                        )) {
                            Label(a.displayName, title: { Text(a.displayName) })
                                .badge(a.icon)
                        }
                    }
                } header: {
                    Text("Allergens")
                } footer: {
                    Text("Allergens are flagged prominently and affect place scoring.")
                }

                // ── Cuisine preferences ────────────────────────────────────
                Section("Favourite Cuisines") {
                    ForEach(CuisinePreference.allCases) { c in
                        Toggle(isOn: Binding(
                            get: { vm.dietaryProfile.cuisinePreferences.contains(c) },
                            set: {
                                if $0 { vm.dietaryProfile.cuisinePreferences.insert(c) }
                                else  { vm.dietaryProfile.cuisinePreferences.remove(c) }
                            }
                        )) {
                            Label(c.displayName, title: { Text(c.displayName) })
                                .badge(c.icon)
                        }
                    }
                }
            }
            .navigationTitle("Add Passenger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        tripVM.addPassenger(vm.buildPassenger())
                        dismiss()
                    }
                    .disabled(!vm.isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
