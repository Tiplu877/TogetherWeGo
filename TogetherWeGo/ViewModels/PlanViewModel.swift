//
//  PlanViewModel.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/11/26.
//


import Foundation
import Observation
import FirebaseFirestore

@Observable
class PlanViewModel {
    var activities: [Activity] = []
    var errorMessage: String?

    private let service = TripService()
    private var listener: ListenerRegistration?
    private var tripID = ""

    func start(tripID: String) {
        self.tripID = tripID
        listener?.remove()
        listener = service.listenToActivities(tripID: tripID) { [weak self] activities in
            Task { @MainActor in
                self?.activities = activities.sorted { $0.startTime < $1.startTime }
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    // Just one day's activities, in time order
    func schedule(for day: Date) -> [Activity] {
        activities.filter { Calendar.current.isDate($0.startTime, inSameDayAs: day) }
    }

    func add(_ activity: Activity) {
        do {
            try service.addActivity(activity, tripID: tripID)
        } catch {
            errorMessage = "Couldn't save that activity. Try again."
        }
    }

    func delete(_ activity: Activity) {
        service.deleteActivity(activity.id, tripID: tripID)
    }
}