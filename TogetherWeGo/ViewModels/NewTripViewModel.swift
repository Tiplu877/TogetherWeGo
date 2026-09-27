import Foundation
import Observation

@Observable
class NewTripViewModel {
    // What the user types
    var name = ""
    var destination = ""
    var startDate = Date.now
    var endDate = Date.now.addingTimeInterval(86400 * 3)
    var budgetText = ""

    // Filled in by the screen so we can catch duplicate names
    var existingNames: [String] = []

    // Only show red messages after the user tries to save
    var showErrors = false

    static let maxTripDays = 30

    // MARK: - Cleaned-up values

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDestination: String {
        destination.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Turns "$1,200" into 1200. Returns nil if it isn't a number.
    private var budgetValue: Double? {
        let cleaned = budgetText
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }

    // MARK: - Error messages (nil means "no problem")

    var nameError: String? {
        if trimmedName.isEmpty { return "Give your trip a name." }                 // syntactic
        if trimmedName.count > 40 { return "Keep the name under 40 characters." }  // syntactic
        if existingNames.contains(where: { $0.lowercased() == trimmedName.lowercased() }) {
            return "You already have a trip with this name."                       // semantic
        }
        return nil
    }

    var destinationError: String? {
        if trimmedDestination.isEmpty { return "Where are you going?" }            // syntactic
        return nil
    }

    var budgetError: String? {
        guard let budget = budgetValue, budget.isFinite else {
            return "Enter a number, like 500."                                     // syntactic
        }
        if budget <= 0 { return "Budget must be more than $0." }                   // semantic
        if budget > 100_000 { return "That's over $100,000. Double-check it." }    // semantic
        return nil
    }

    var dateError: String? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        if start < today { return "The trip can't start in the past." }            // semantic
        if end < start { return "The trip has to end after it starts." }           // semantic
        let days = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
        if days > Self.maxTripDays {
            return "Trips can be up to \(Self.maxTripDays) days."                  // semantic
        }
        return nil
    }

    var isValid: Bool {
        nameError == nil && destinationError == nil && budgetError == nil && dateError == nil
    }

    // Returns a new Trip if everything is valid, otherwise nil
    func makeTrip(creatorID: String) -> Trip? {
        showErrors = true
        guard isValid, let budget = budgetValue else { return nil }
        return Trip(name: trimmedName,
                    destination: trimmedDestination,
                    startDate: startDate,
                    endDate: endDate,
                    budget: budget,
                    memberIDs: [creatorID])
    }
}
