import SwiftUI

struct NewTripView: View {
    @Environment(TripStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var auth
    @State private var form = NewTripViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip") {
                    TextField("Trip name (e.g. Spring Break)", text: $form.name)
                    errorText(form.nameError)

                    TextField("Destination (e.g. Orlando, FL)", text: $form.destination)
                    errorText(form.destinationError)
                }

                Section("Dates") {
                    DatePicker("Start", selection: $form.startDate,
                               in: Calendar.current.startOfDay(for: .now)...,
                               displayedComponents: .date)
                    DatePicker("End", selection: $form.endDate,
                               in: form.startDate...,
                               displayedComponents: .date)
                    errorText(form.dateError)
                }

                Section("Budget") {
                    TextField("Total group budget ($)", text: $form.budgetText)
                        .keyboardType(.decimalPad)
                    errorText(form.budgetError)
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { save() }
                }
            }
            .onAppear {
                form.existingNames = store.trips.map { $0.name }
            }
        }
    }

    private func save() {
        guard let userID = auth.userID else { return }
        if let trip = form.makeTrip(creatorID: userID) {
            store.addTrip(trip)
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

#Preview {
    NewTripView()
        .environment(TripStore())
        .environment(AuthViewModel(loadCurrentUser: false))
}
