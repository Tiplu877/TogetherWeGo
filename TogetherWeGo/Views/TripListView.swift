import SwiftUI

struct TripListView: View {
    @Environment(TripStore.self) private var store
    @State private var showingNewTrip = false

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
            .toolbar {
                Button {
                    showingNewTrip = true
                } label: {
                    Label("New Trip", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingNewTrip) {
                NewTripView()
            }
        }
    }
}

#Preview {
    TripListView()
        .environment(TripStore())
}
