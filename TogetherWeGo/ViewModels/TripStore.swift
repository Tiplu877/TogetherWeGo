import Foundation
import Observation
import FirebaseFirestore

@Observable
class TripStore {
    var trips: [Trip]
    var errorMessage: String?

    private let service = TripService()
    private var listener: ListenerRegistration?

    init(trips: [Trip] = []) {
        self.trips = trips
    }

    func startListening(userID: String) {
        stopListening()
        listener = service.listenToTrips(for: userID) { [weak self] trips in
            Task { @MainActor in
                self?.trips = trips.sorted { $0.startDate < $1.startDate }
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        trips = []
    }

    func addTrip(_ trip: Trip) {
        do {
            try service.createTrip(trip)
        } catch {
            errorMessage = "Couldn't save that trip. Please try again."
        }
    }

    // Returns nil on success, or a message explaining what went wrong
    func joinTrip(code rawCode: String, userID: String) async -> String? {
        let code = rawCode.uppercased().trimmingCharacters(in: .whitespaces)

        // Syntactic: is it shaped like a code?
        guard code.count == 6, code.allSatisfy({ Trip.codeCharacters.contains($0) }) else {
            return "Codes are 6 letters and numbers, like K7QX2M."
        }
        // Semantic: does joining make sense?
        if trips.contains(where: { $0.joinCode == code }) {
            return "You're already in this trip."
        }

        do {
            try await service.joinTrip(code: code, userID: userID)
            return nil
        } catch TripServiceError.codeNotFound {
            return "No trip uses that code. Double-check it with your friend."
        } catch {
            return "Couldn't join. Check your internet connection."
        }
    }
}
