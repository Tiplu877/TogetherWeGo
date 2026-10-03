import Foundation

struct Trip: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var budget: Double
    var memberIDs: [String]
    var createdBy: String
    var joinCode: String = Trip.makeJoinCode()

    var lengthInDays: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return days + 1
    }

    // No 0/O or 1/I, so codes are easy to read out loud
    static let codeCharacters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func makeJoinCode() -> String {
        String((0..<6).map { _ in codeCharacters.randomElement()! })
    }
}

extension Trip {
    static let samples: [Trip] = [
        Trip(name: "Spring Break", destination: "Orlando, FL",
             startDate: .now, endDate: .now.addingTimeInterval(86400 * 4),
             budget: 1200, memberIDs: ["a", "b", "c"], createdBy: "a"),
        Trip(name: "Family Reunion", destination: "Denver, CO",
             startDate: .now.addingTimeInterval(86400 * 30),
             endDate: .now.addingTimeInterval(86400 * 33),
             budget: 2500, memberIDs: ["a", "d"], createdBy: "a")
    ]
}
