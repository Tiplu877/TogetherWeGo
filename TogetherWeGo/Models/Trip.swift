import Foundation

struct Trip: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var budget: Double
    var memberIDs: [String]

    var lengthInDays: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return days + 1
    }
}

extension Trip {
    static let samples: [Trip] = [
        Trip(name: "Spring Break", destination: "Orlando, FL",
             startDate: .now, endDate: .now.addingTimeInterval(86400 * 4),
             budget: 1200, memberIDs: ["a", "b", "c"]),
        Trip(name: "Family Reunion", destination: "Denver, CO",
             startDate: .now.addingTimeInterval(86400 * 30),
             endDate: .now.addingTimeInterval(86400 * 33),
             budget: 2500, memberIDs: ["a", "d"])
    ]
}
