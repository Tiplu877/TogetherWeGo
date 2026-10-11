//
//  AddActivityViewModel.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/11/26.
//


import Foundation
import Observation

@Observable
class AddActivityViewModel {
    var title = ""
    var placeName = ""
    var notes = ""
    var day: Date = .now
    var startTime: Date = .now
    var hasEndTime = false
    var endTime: Date = .now
    var showErrors = false

    private var tripDays: [Date] = []
    private var existingActivities: [Activity] = []

    func setUp(day: Date, tripDays: [Date], existing: [Activity]) {
        guard self.tripDays.isEmpty else { return }   // only the first time
        self.day = day
        self.tripDays = tripDays
        self.existingActivities = existing
        // Default: 10:00 AM to 11:00 AM
        startTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: day) ?? day
        endTime = startTime.addingTimeInterval(3600)
    }

    // MARK: - Combine the chosen day with the chosen time

    private func combine(_ day: Date, _ time: Date) -> Date {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: parts.hour ?? 0, minute: parts.minute ?? 0,
                             second: 0, of: day) ?? day
    }

    var start: Date { combine(day, startTime) }
    var end: Date? { hasEndTime ? combine(day, endTime) : nil }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedPlace: String { placeName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedNotes: String { notes.trimmingCharacters(in: .whitespacesAndNewlines) }

    // MARK: - Validation

    var titleError: String? {
        if trimmedTitle.isEmpty { return "What's the activity?" }                        // syntactic
        if trimmedTitle.count > 50 { return "Keep it under 50 characters." }             // syntactic
        return nil
    }

    var placeError: String? {
        trimmedPlace.count > 60 ? "Keep the place under 60 characters." : nil            // syntactic
    }

    var notesError: String? {
        trimmedNotes.count > 300 ? "Keep notes under 300 characters." : nil              // syntactic
    }

    var timeError: String? {
        if !tripDays.contains(where: { Calendar.current.isDate($0, inSameDayAs: day) }) {
            return "Pick a day during the trip."                                         // semantic
        }
        if let end, end <= start {
            return "End time must be after the start time."                              // semantic
        }
        return nil
    }

    // A warning, not an error: groups sometimes split up on purpose
    var overlapWarning: String? {
        let newEnd = end ?? start.addingTimeInterval(3600)
        guard let clash = existingActivities.first(where: { other in
            let otherEnd = other.endTime ?? other.startTime.addingTimeInterval(3600)
            return other.startTime < newEnd && start < otherEnd
        }) else { return nil }
        return "Overlaps with \"\(clash.title)\" at \(clash.startTime.formatted(date: .omitted, time: .shortened)). You can still add it."
    }

    var isValid: Bool {
        titleError == nil && placeError == nil && notesError == nil && timeError == nil
    }

    func makeActivity(userID: String, userName: String) -> Activity? {
        showErrors = true
        guard isValid else { return nil }
        return Activity(title: trimmedTitle,
                        startTime: start,
                        endTime: end,
                        placeName: trimmedPlace.isEmpty ? nil : trimmedPlace,
                        notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                        addedBy: userID,
                        addedByName: userName.isEmpty ? "Someone" : userName)
    }
}