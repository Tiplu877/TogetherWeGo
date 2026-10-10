//
//  TripServiceError.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/3/26.
//


import Foundation
import FirebaseFirestore

enum TripServiceError: Error {
    case codeNotFound
}

struct TripService {
    // Computed, so Firestore isn't touched until FirebaseApp.configure() has run
    private var db: Firestore { Firestore.firestore() }

    // Calls onChange every time any of this user's trips change, on any phone
    func listenToTrips(for userID: String,
                       onChange: @escaping ([Trip]) -> Void) -> ListenerRegistration {
        db.collection("trips")
            .whereField("memberIDs", arrayContains: userID)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Trip listener error: \(error?.localizedDescription ?? "unknown")")
                    return
                }
                let trips = documents.compactMap { try? $0.data(as: Trip.self) }
                onChange(trips)
            }
    }

    // Saves the trip AND its join code together. Both succeed or neither does.
    func createTrip(_ trip: Trip) throws {
        let batch = db.batch()
        try batch.setData(from: trip, forDocument: db.collection("trips").document(trip.id))
        batch.setData(["tripID": trip.id, "createdBy": trip.createdBy],
                      forDocument: db.collection("joinCodes").document(trip.joinCode))
        batch.commit { error in
            if let error { print("Save failed: \(error.localizedDescription)") }
        }
    }

    // Looks up the code, then adds this user to that trip's members
    func joinTrip(code: String, userID: String, userName: String) async throws {
        let codeDoc = try await db.collection("joinCodes").document(code).getDocument()
        guard let tripID = codeDoc.data()?["tripID"] as? String else {
            throw TripServiceError.codeNotFound
        }
        try await db.collection("trips").document(tripID).updateData([
            "memberIDs": FieldValue.arrayUnion([userID]),
            "memberNames.\(userID)": userName
        ])
    }
    // MARK: - Checklist

    private func checklist(_ tripID: String) -> CollectionReference {
        db.collection("trips").document(tripID).collection("checklist")
    }

    func listenToChecklist(tripID: String,
                           onChange: @escaping ([ChecklistItem]) -> Void) -> ListenerRegistration {
        checklist(tripID).addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Checklist listener error: \(error?.localizedDescription ?? "unknown")")
                return
            }
            onChange(documents.compactMap { try? $0.data(as: ChecklistItem.self) })
        }
    }

    func addChecklistItem(_ item: ChecklistItem, tripID: String) throws {
        try checklist(tripID).document(item.id).setData(from: item)
    }

    func setChecklistItem(_ itemID: String, done: Bool, tripID: String) {
        checklist(tripID).document(itemID).updateData(["isDone": done])
    }

    func deleteChecklistItem(_ itemID: String, tripID: String) {
        checklist(tripID).document(itemID).delete()
    }
    // MARK: - Shared listener helper

    // One function that can listen to ANY collection of Codable items
    private func listen<T: Decodable>(to query: Query, as type: T.Type,
                                      onChange: @escaping ([T]) -> Void) -> ListenerRegistration {
        query.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Listener error: \(error?.localizedDescription ?? "unknown")")
                return
            }
            onChange(documents.compactMap { try? $0.data(as: T.self) })
        }
    }

    // MARK: - Expenses

    private func expenses(_ tripID: String) -> CollectionReference {
        db.collection("trips").document(tripID).collection("expenses")
    }

    func listenToExpenses(tripID: String,
                          onChange: @escaping ([Expense]) -> Void) -> ListenerRegistration {
        listen(to: expenses(tripID), as: Expense.self, onChange: onChange)
    }

    func addExpense(_ expense: Expense, tripID: String) throws {
        try expenses(tripID).document(expense.id).setData(from: expense)
    }

    func deleteExpense(_ expenseID: String, tripID: String) {
        expenses(tripID).document(expenseID).delete()
    }
    // MARK: - Chat

    private func messages(_ tripID: String) -> CollectionReference {
        db.collection("trips").document(tripID).collection("messages")
    }

    // Only the newest 100 messages, oldest first
    func listenToMessages(tripID: String,
                          onChange: @escaping ([ChatMessage]) -> Void) -> ListenerRegistration {
        listen(to: messages(tripID).order(by: "sentAt").limit(toLast: 100),
               as: ChatMessage.self,
               onChange: onChange)
    }

    func sendMessage(_ message: ChatMessage, tripID: String) throws {
        try messages(tripID).document(message.id).setData(from: message)
    }

    func deleteMessage(_ messageID: String, tripID: String) {
        messages(tripID).document(messageID).delete()
    }
}
