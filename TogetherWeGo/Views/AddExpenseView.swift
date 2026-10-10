//
//  AddExpenseView.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/10/26.
//


import SwiftUI

struct AddExpenseView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    let onSave: (Expense) -> Void

    @State private var form = AddExpenseViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("What was it?") {
                    TextField("e.g. Dinner at Joe's", text: $form.title)
                    errorText(form.titleError)

                    TextField("Amount ($)", text: $form.amountText)
                        .keyboardType(.decimalPad)
                    errorText(form.amountError)

                    Picker("Category", selection: $form.category) {
                        ForEach(Expense.Category.allCases) { category in
                            Label(category.label, systemImage: category.icon).tag(category)
                        }
                    }
                }

                Section("Paid by") {
                    Picker("Paid by", selection: $form.paidBy) {
                        ForEach(trip.memberIDs, id: \.self) { id in
                            Text(displayName(id)).tag(id)
                        }
                    }
                }

                Section {
                    ForEach(trip.memberIDs, id: \.self) { id in
                        Toggle(displayName(id), isOn: Binding(
                            get: { form.splitAmong.contains(id) },
                            set: { isOn in
                                if isOn { form.splitAmong.insert(id) } else { form.splitAmong.remove(id) }
                            }
                        ))
                    }
                    errorText(form.splitError)
                } header: {
                    Text("Split between")
                } footer: {
                    if let each = form.perPersonText {
                        Text("\(each) each")
                    }
                }
            }
            .navigationTitle("Add Expense")
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
                if let me = auth.userID {
                    form.setUp(members: trip.memberIDs, currentUser: me)
                }
            }
        }
    }

    private func displayName(_ id: String) -> String {
        id == auth.userID ? "You" : trip.name(for: id)
    }

    private func save() {
        guard let me = auth.userID else { return }
        if let expense = form.makeExpense(addedBy: me) {
            onSave(expense)
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