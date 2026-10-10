//
//  Settlement.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/10/26.
//


import Foundation

struct Settlement: Identifiable {
    let from: String   // who pays
    let to: String     // who gets paid
    let cents: Int
    var id: String { "\(from)-\(to)" }
}

enum BudgetCalculator {
    // Money is calculated in whole cents to avoid rounding errors
    static func cents(_ dollars: Double) -> Int {
        Int((dollars * 100).rounded())
    }

    // Positive = this person is owed money. Negative = they owe money.
    static func balances(for expenses: [Expense]) -> [String: Int] {
        var balance: [String: Int] = [:]

        for expense in expenses {
            let total = cents(expense.amount)
            let people = expense.splitAmong.sorted()
            guard !people.isEmpty else { continue }

            balance[expense.paidBy, default: 0] += total

            // $100 split 3 ways = 3334 + 3333 + 3333 cents, so nothing is lost
            let share = total / people.count
            let leftover = total % people.count
            for (index, person) in people.enumerated() {
                balance[person, default: 0] -= share + (index < leftover ? 1 : 0)
            }
        }
        return balance
    }

    // Turns balances into the fewest simple "A pays B" payments
    static func settlements(from balances: [String: Int]) -> [Settlement] {
        var owes = balances.filter { $0.value < 0 }
            .map { (person: $0.key, cents: -$0.value) }
            .sorted { $0.cents > $1.cents }
        var owed = balances.filter { $0.value > 0 }
            .map { (person: $0.key, cents: $0.value) }
            .sorted { $0.cents > $1.cents }

        var result: [Settlement] = []
        var i = 0, j = 0

        while i < owes.count && j < owed.count {
            let amount = min(owes[i].cents, owed[j].cents)
            result.append(Settlement(from: owes[i].person, to: owed[j].person, cents: amount))
            owes[i].cents -= amount
            owed[j].cents -= amount
            if owes[i].cents == 0 { i += 1 }
            if owed[j].cents == 0 { j += 1 }
        }
        return result
    }
}

extension Int {
    // 2450 → "$24.50"
    var dollars: String {
        (Double(self) / 100).formatted(.currency(code: "USD"))
    }
}