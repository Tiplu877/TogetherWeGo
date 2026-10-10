//
//  JoinTripView.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/3/26.
//


import SwiftUI

struct JoinTripView: View {
    @Environment(TripStore.self) private var store
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var errorMessage: String?
    @State private var isJoining = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("6-character code", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.title2.monospaced())
                } footer: {
                    Text("Ask whoever created the trip for its code.")
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Join a Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isJoining {
                        ProgressView()
                    } else {
                        Button("Join") { Task { await join() } }
                    }
                }
            }
        }
    }

    private func join() async {
        guard let userID = auth.userID else { return }
        isJoining = true
        errorMessage = await store.joinTrip(code: code, userID: userID, userName: auth.displayName)
        isJoining = false
        if errorMessage == nil { dismiss() }
    }
}

#Preview {
    JoinTripView()
        .environment(TripStore())
        .environment(AuthViewModel(loadCurrentUser: false))
}
