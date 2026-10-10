//
//  AddExpenseViewModel.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/10/26.
//


import Foundation
import Observation

@Observable
class AddExpenseViewModel {
    var title = ""
    var amountText = ""
    var category: Expense.Category = .food
    var paidBy = ""
    var splitAmong: Set<String> = []
    var showErrors = false

    // Default: I paid, and it's split with everyone
    func setUp(members: [String], currentUser: String) {
        guard paidBy.isEmpty else { return }   // only the first time
        paidBy = currentUser
        splitAmong = Set(members)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var amountValue: Double? {
        let cleaned = amountText
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }

    // MARK: - Validation

    var titleError: String? {
        if trimmedTitle.isEmpty { return "What was this expense for?" }               // syntactic
        if trimmedTitle.count > 40 { return "Keep it under 40 characters." }          // syntactic
        return nil
    }

    var amountError: String? {
        guard let amount = amountValue, amount.isFinite else {
            return "Enter an amount, like 24.50."                                     // syntactic
        }
        let cents = amount * 100
        if abs(cents - cents.rounded()) > 0.0001 {
            return "Use at most 2 decimal places."                                    // syntactic
        }
        if amount <= 0 { return "Amount must be more than $0." }                      // semantic
        if amount > 10_000 { return "That's over $10,000. Double-check it." }         // semantic
        return nil
    }

    var splitError: String? {
        splitAmong.isEmpty ? "Pick at least one person to split with." : nil          // semantic
    }

    var perPersonText: String? {
        guard let amount = amountValue, amount > 0, !splitAmong.isEmpty else { return nil }
        return (amount / Double(splitAmong.count)).formatted(.currency(code: "USD"))
    }

    var isValid: Bool {
        titleError == nil && amountError == nil && splitError == nil && !paidBy.isEmpty
    }

    func makeExpense(addedBy userID: String) -> Expense? {
        showErrors = true
        guard isValid, let amount = amountValue else { return nil }
        return Expense(title: trimmedTitle,
                       amount: amount,
                       category: category,
                       paidBy: paidBy,
                       splitAmong: splitAmong.sorted(),
                       addedBy: userID)
    }
}