//
//  Expense.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/10/26.
//


import Foundation

struct Expense: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var amount: Double
    var category: Category
    var paidBy: String          // user ID of who paid
    var splitAmong: [String]    // user IDs sharing the cost
    var addedBy: String
    var createdAt: Date = .now

    enum Category: String, Codable, CaseIterable, Identifiable {
        case food, lodging, transport, activities, other

        var id: Self { self }
        var label: String { rawValue.capitalized }

        var icon: String {
            switch self {
            case .food: "fork.knife"
            case .lodging: "bed.double.fill"
            case .transport: "car.fill"
            case .activities: "ticket.fill"
            case .other: "tag.fill"
            }
        }
    }
}