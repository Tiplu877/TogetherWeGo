import SwiftUI

struct TripListView: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        NavigationStack {
            List(store.trips) { trip in
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
                        .font(.headline)
                    Text(trip.destination)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(trip.lengthInDays) days · \(trip.memberIDs.count) travelers")
                        .font(.caption)
                }
                .accessibilityElement(children: .combine)
            }
            .navigationTitle("My Trips")
        }
    }
}

#Preview {
    TripListView()
        .environment(TripStore())
}
