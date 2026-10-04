//
//  ChecklistViewModel.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/4/26.
//


import Foundation
import Observation
import FirebaseFirestore

@Observable
class ChecklistViewModel {
    var items: [ChecklistItem] = []
    var newItemTitle = ""
    var errorMessage: String?

    private let service = TripService()
    private var listener: ListenerRegistration?
    private var tripID = ""

    var doneCount: Int { items.filter(\.isDone).count }

    func start(tripID: String) {
        self.tripID = tripID
        listener?.remove()
        listener = service.listenToChecklist(tripID: tripID) { [weak self] items in
            Task { @MainActor in
                self?.items = items.sorted { $0.createdAt < $1.createdAt }
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func addItem(userID: String, userName: String) {
        let title = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        if title.isEmpty {                                                      // syntactic
            errorMessage = "Type something to add."
            return
        }
        if title.count > 60 {                                                   // syntactic
            errorMessage = "Keep items under 60 characters."
            return
        }
        if items.contains(where: { $0.title.lowercased() == title.lowercased() }) {  // semantic
            errorMessage = "\"\(title)\" is already on the list."
            return
        }

        let item = ChecklistItem(title: title,
                                 addedBy: userID,
                                 addedByName: userName.isEmpty ? "Someone" : userName)
        do {
            try service.addChecklistItem(item, tripID: tripID)
            newItemTitle = ""
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't add that item. Try again."
        }
    }

    func toggle(_ item: ChecklistItem) {
        service.setChecklistItem(item.id, done: !item.isDone, tripID: tripID)
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            service.deleteChecklistItem(items[index].id, tripID: tripID)
        }
    }
}