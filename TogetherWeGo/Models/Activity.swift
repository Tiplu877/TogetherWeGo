//
//  Activity.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/11/26.
//


import Foundation

struct Activity: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var startTime: Date
    var endTime: Date? = nil
    var placeName: String? = nil
    var notes: String? = nil
    var latitude: Double? = nil      // filled in later by the map
    var longitude: Double? = nil
    var addedBy: String
    var addedByName: String
    var createdAt: Date = .now
}