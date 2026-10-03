import SwiftUI

struct TripListView: View {
    @Environment(TripStore.self) private var store
    @Environment(AuthViewModel.self) private var auth
    @State private var showingNewTrip = false
    @State private var showingJoinTrip = false

    var body: some View {
        NavigationStack {
            List(store.trips) { trip in
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
                        .font(.headline)
                    Text(trip.destination)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(trip.lengthInDays) days · \(trip.memberIDs.count) travelers · Code \(trip.joinCode)")
                        .font(.caption)
                }
                .accessibilityElement(children: .combine)
            }
            .overlay {
                if store.trips.isEmpty {
                    ContentUnavailableView(
                        "No trips yet",
                        systemImage: "airplane.departure",
                        description: Text("Tap + to plan a trip, or join a friend's trip with their code.")
                    )
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign Out") {
                        store.stopListening()
                        auth.signOut()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingNewTrip = true
                        } label: {
                            Label("New Trip", systemImage: "plus")
                        }
                        Button {
                            showingJoinTrip = true
                        } label: {
                            Label("Join with Code", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewTrip) { NewTripView() }
            .sheet(isPresented: $showingJoinTrip) { JoinTripView() }
            .task(id: auth.userID) {
                if let userID = auth.userID {
                    store.startListening(userID: userID)
                }
            }
        }
    }
}

#Preview {
    TripListView()
        .environment(TripStore(trips: Trip.samples))
        .environment(AuthViewModel(loadCurrentUser: false))
}
