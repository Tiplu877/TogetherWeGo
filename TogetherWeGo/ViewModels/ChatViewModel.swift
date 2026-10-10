//
//  ChatViewModel.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/10/26.
//


import Foundation
import Observation
import FirebaseFirestore

@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    var draft = ""
    var sendAsAnnouncement = false
    var errorMessage: String?

    static let maxLength = 500

    private let service = TripService()
    private var listener: ListenerRegistration?
    private var tripID = ""

    var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSend: Bool {
        !trimmedDraft.isEmpty && trimmedDraft.count <= Self.maxLength
    }

    var latestAnnouncement: ChatMessage? {
        messages.last { $0.isAnnouncement }
    }

    func start(tripID: String) {
        self.tripID = tripID
        listener?.remove()
        listener = service.listenToMessages(tripID: tripID) { [weak self] messages in
            Task { @MainActor in
                self?.messages = messages.sorted { $0.sentAt < $1.sentAt }
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func send(userID: String, userName: String) {
        guard !trimmedDraft.isEmpty else { return }                       // syntactic
        guard trimmedDraft.count <= Self.maxLength else {                 // syntactic
            errorMessage = "Messages can be up to \(Self.maxLength) characters."
            return
        }

        let message = ChatMessage(text: trimmedDraft,
                                  senderID: userID,
                                  senderName: userName.isEmpty ? "Someone" : userName,
                                  isAnnouncement: sendAsAnnouncement)
        do {
            try service.sendMessage(message, tripID: tripID)
            draft = ""
            sendAsAnnouncement = false
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't send. Try again."
        }
    }

    func delete(_ message: ChatMessage) {
        service.deleteMessage(message.id, tripID: tripID)
    }
}