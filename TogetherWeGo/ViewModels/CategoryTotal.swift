//
//  CategoryTotal.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/10/26.
//


import Foundation
import Observation
import FirebaseFirestore

struct CategoryTotal: Identifiable {
    let category: Expense.Category
    let cents: Int
    var id: Expense.Category { category }
}

@Observable
class BudgetViewModel {
    var expenses: [Expense] = []
    var errorMessage: String?

    private let service = TripService()
    private var listener: ListenerRegistration?
    private var tripID = ""

    func start(tripID: String) {
        self.tripID = tripID
        listener?.remove()
        listener = service.listenToExpenses(tripID: tripID) { [weak self] expenses in
            Task { @MainActor in
                self?.expenses = expenses.sorted { $0.createdAt > $1.createdAt }   // newest first
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    var totalSpentCents: Int {
        expenses.reduce(0) { $0 + BudgetCalculator.cents($1.amount) }
    }

    var categoryTotals: [CategoryTotal] {
        Expense.Category.allCases.compactMap { category in
            let cents = expenses
                .filter { $0.category == category }
                .reduce(0) { $0 + BudgetCalculator.cents($1.amount) }
            return cents > 0 ? CategoryTotal(category: category, cents: cents) : nil
        }
    }

    var settlements: [Settlement] {
        BudgetCalculator.settlements(from: BudgetCalculator.balances(for: expenses))
    }

    func add(_ expense: Expense) {
        do {
            try service.addExpense(expense, tripID: tripID)
        } catch {
            errorMessage = "Couldn't save that expense. Try again."
        }
    }

    func delete(_ expense: Expense) {
        service.deleteExpense(expense.id, tripID: tripID)
    }
}