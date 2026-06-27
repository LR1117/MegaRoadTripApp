import SwiftUI

struct MapOverlayView: View {
    @EnvironmentObject var tripVM: TripViewModel

    var body: some View {
        HStack(spacing: 12) {
            TripActionButton(label: "Food",      icon: "fork.knife",    color: .orange) {
                tripVM.findNearby(category: .food)
            }
            TripActionButton(label: "Gas",       icon: "fuelpump.fill", color: .green) {
                tripVM.findNearby(category: .gas)
            }
            TripActionButton(label: "Rest Stop", icon: "toilet.fill",   color: .blue) {
                tripVM.findNearby(category: .restroom)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }
}

struct TripActionButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption2.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
