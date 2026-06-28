import SwiftUI

struct AddPassengerView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @StateObject private var vm = PassengerViewModel()
    @Environment(\.dismiss) private var dismiss

    let emojiOptions = ["🧑","👦","👧","👨","👩","🧒","🧓","👴","👵","🧔","👱"]

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Identity
                Section("Name & Avatar") {
                    TextField("Passenger name", text: $vm.name)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose an avatar")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(emojiOptions, id: \.self) { e in
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
                                                .stroke(
                                                    vm.emoji == e ? Color.accentColor : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                        .onTapGesture { vm.emoji = e }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    Toggle("This person is driving", isOn: $vm.isDriver)
                }

                // MARK: - Dietary Restrictions
                Section {
                    ForEach(DietaryRestriction.allCases) { r in
                        Toggle(isOn: Binding(
                            get: { vm.dietaryProfile.restrictions.contains(r) },
                            set: { enabled in
                                if enabled {
                                    vm.dietaryProfile.restrictions.insert(r)
                                } else {
                                    vm.dietaryProfile.restrictions.remove(r)
                                }
                            }
                        )) {
                            HStack(spacing: 8) {
                                Text(r.icon)
                                Text(r.displayName)
                            }
                        }
                    }
                } header: {
                    Text("Dietary Restrictions")
                } footer: {
                    Text("These help RouteSnack prioritise restaurants that suit everyone.")
                }

                // MARK: - Allergens
                Section {
                    ForEach(Allergen.allCases) { a in
                        Toggle(isOn: Binding(
                            get: { vm.dietaryProfile.allergens.contains(a) },
                            set: { enabled in
                                if enabled {
                                    vm.dietaryProfile.allergens.insert(a)
                                } else {
                                    vm.dietaryProfile.allergens.remove(a)
                                }
                            }
                        )) {
                            HStack(spacing: 8) {
                                Text(a.icon)
                                Text(a.displayName)
                            }
                        }
                    }
                } header: {
                    Text("Allergens")
                } footer: {
                    Text("Allergens are flagged prominently and affect place scoring.")
                }

                // MARK: - Cuisine Preferences
                Section("Favourite Cuisines") {
                    ForEach(CuisinePreference.allCases) { c in
                        Toggle(isOn: Binding(
                            get: { vm.dietaryProfile.cuisinePreferences.contains(c) },
                            set: { enabled in
                                if enabled {
                                    vm.dietaryProfile.cuisinePreferences.insert(c)
                                } else {
                                    vm.dietaryProfile.cuisinePreferences.remove(c)
                                }
                            }
                        )) {
                            HStack(spacing: 8) {
                                Text(c.icon)
                                Text(c.displayName)
                            }
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
