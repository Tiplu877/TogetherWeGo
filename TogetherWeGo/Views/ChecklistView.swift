//
//  ChecklistView.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/4/26.
//


import SwiftUI

struct ChecklistView: View {
    @Environment(AuthViewModel.self) private var auth
    let tripID: String
    @State private var model = ChecklistViewModel()

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Add an item (e.g. Sunscreen)", text: $model.newItemTitle)
                        .onSubmit(add)
                    Button("Add", action: add)
                        .disabled(model.newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if let error = model.errorMessage {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("\(model.doneCount) of \(model.items.count) packed") {
                if model.items.isEmpty {
                    Text("Nothing on the list yet. Add the first item above.")
                        .foregroundStyle(.secondary)
                }
                ForEach(model.items) { item in
                    Button {
                        model.toggle(item)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(item.isDone ? .green : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .strikethrough(item.isDone)
                                    .foregroundStyle(.primary)
                                Text("Added by \(item.addedByName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityLabel("\(item.title), \(item.isDone ? "packed" : "not packed"), added by \(item.addedByName)")
                    .accessibilityHint("Double-tap to toggle")
                }
                .onDelete { offsets in
                    model.delete(at: offsets)
                }
            }
        }
        .task {
            // Previews have no signed-in user, so they skip Firestore
            guard auth.userID != nil else { return }
            model.start(tripID: tripID)
        }
        .onDisappear {
            model.stop()
        }
    }

    private func add() {
        guard let userID = auth.userID else { return }
        model.addItem(userID: userID, userName: auth.displayName)
    }
}