//
//  ChatMessage.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/10/26.
//


import Foundation

struct ChatMessage: Identifiable, Codable {
    var id: String = UUID().uuidString
    var text: String
    var senderID: String
    var senderName: String
    var isAnnouncement: Bool = false
    var sentAt: Date = .now

extension Date {
    // "3:42 PM" if today, otherwise "Oct 10, 3:42 PM"
    var chatTimestamp: String {
        Calendar.current.isDateInToday(self)
            ? formatted(date: .omitted, time: .shortened)
            : formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}