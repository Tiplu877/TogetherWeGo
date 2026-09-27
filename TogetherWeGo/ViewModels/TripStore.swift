import Foundation
import Observation

@Observable
class TripStore {
    var trips: [Trip] = Trip.samples

    func addTrip(_ trip: Trip) {
        trips.append(trip)
    }
}
