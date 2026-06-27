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
                Section("Name & Avatar") {
                    TextField("Name", text: $vm.draft.name)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(vm.emojiOptions, id: \.self) { e in
                                Text(e)
                                    .font(.largeTitle)
                                    .padding(6)
                                    .background(vm.draft.emoji == e ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture { vm.draft.emoji = e }
                            }
                        }
                    }
                }

                Section("Dietary Restrictions") {
                    ForEach(DietaryRestriction.allCases) { r in
                        Toggle(r.displayName, isOn: Binding(
                            get: { vm.draft.dietaryProfile.restrictions.contains(r) },
                            set: { if $0 { vm.draft.dietaryProfile.restrictions.insert(r) }
                                  else { vm.draft.dietaryProfile.restrictions.remove(r) } }
                        ))
                    }
                }

                Section("Allergens") {
                    ForEach(Allergen.allCases) { a in
                        Toggle(a.displayName, isOn: Binding(
                            get: { vm.draft.dietaryProfile.allergens.contains(a) },
                            set: { if $0 { vm.draft.dietaryProfile.allergens.insert(a) }
                                  else { vm.draft.dietaryProfile.allergens.remove(a) } }
                        ))
                    }
                }

                Section("Cuisine Preferences") {
                    ForEach(CuisinePreference.allCases) { c in
                        Toggle(c.displayName, isOn: Binding(
                            get: { vm.draft.dietaryProfile.cuisinePreferences.contains(c) },
                            set: { if $0 { vm.draft.dietaryProfile.cuisinePreferences.insert(c) }
                                  else { vm.draft.dietaryProfile.cuisinePreferences.remove(c) } }
                        ))
                    }
                }
            }
            .navigationTitle("Add Passenger")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        vm.saveTo(trip: &tripVM.trip)
                        dismiss()
                    }
                    .disabled(vm.draft.name.isEmpty)
                }
            }
        }
    }
}
