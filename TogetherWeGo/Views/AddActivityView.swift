//
//  AddActivityView.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/11/26.
//


import SwiftUI

struct AddActivityView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    let day: Date
    let existing: [Activity]
    let onSave: (Activity) -> Void

    @State private var form = AddActivityViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    TextField("e.g. Snorkeling tour", text: $form.title)
                    errorText(form.titleError)
                    TextField("Place (optional)", text: $form.placeName)
                    errorText(form.placeError)
                }

                Section("When") {
                    Picker("Day", selection: $form.day) {
                        ForEach(Array(trip.days.enumerated()), id: \.element) { index, date in
                            Text("Day \(index + 1) · \(date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))")
                                .tag(date)
                        }
                    }
                    DatePicker("Starts", selection: $form.startTime, displayedComponents: .hourAndMinute)
                    Toggle("Add end time", isOn: $form.hasEndTime)
                    if form.hasEndTime {
                        DatePicker("Ends", selection: $form.endTime, displayedComponents: .hourAndMinute)
                    }
                    errorText(form.timeError)
                    if let warning = form.overlapWarning {
                        Label(warning, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Notes") {
                    TextField("Tickets, meeting spot, what to bring…", text: $form.notes, axis: .vertical)
                        .lineLimit(2...5)
                    errorText(form.notesError)
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                }
            }
            .onAppear {
                form.setUp(day: day, tripDays: trip.days, existing: existing)
            }
        }
    }

    private func save() {
        guard let userID = auth.userID else { return }
        if let activity = form.makeActivity(userID: userID, userName: auth.displayName) {
            onSave(activity)
            dismiss()
        }
    }

    @ViewBuilder
    private func errorText(_ message: String?) -> some View {
        if form.showErrors, let message {
            Label(message, systemImage: "exclamationmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }
}