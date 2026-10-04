//
//  ChecklistItem.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/4/26.
//


import Foundation

struct ChecklistItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var isDone: Bool = false
    var addedBy: String        // user ID
    var addedByName: String    // shown in the list
    var createdAt: Date = .now
}