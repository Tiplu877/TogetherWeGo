//
//  BudgetView.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/10/26.
//


import SwiftUI
import Charts

struct BudgetView: View {
    @Environment(AuthViewModel.self) private var auth
    let trip: Trip

    @State private var model = BudgetViewModel()
    @State private var showingAddExpense = false

    private var budgetCents: Int { BudgetCalculator.cents(trip.budget) }
    private var isOverBudget: Bool { model.totalSpentCents > budgetCents }

    var body: some View {
        List {
            // Summary
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(model.totalSpentCents.dollars) of \(budgetCents.dollars) spent")
                        .font(.headline)
                    ProgressView(value: Double(min(model.totalSpentCents, budgetCents)),
                                 total: Double(max(budgetCents, 1)))
                        .tint(isOverBudget ? .red : .accentColor)
                    if isOverBudget {
                        Label("Over budget by \((model.totalSpentCents - budgetCents).dollars)",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    } else {
                        Text("\((budgetCents - model.totalSpentCents).dollars) left")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)

                if !model.categoryTotals.isEmpty {
                    Chart(model.categoryTotals) { item in
                        SectorMark(angle: .value("Amount", item.cents),
                                   innerRadius: .ratio(0.6),
                                   angularInset: 2)
                            .foregroundStyle(by: .value("Category", item.category.label))
                    }
                    .frame(height: 180)
                    .accessibilityLabel("Spending by category")
                }

                Button {
                    showingAddExpense = true
                } label: {
                    Label("Add Expense", systemImage: "plus.circle.fill")
                }
            }

            // Who owes whom
            Section("Settle up") {
                if model.settlements.isEmpty {
                    Text("Everyone is even.")
                        .foregroundStyle(.secondary)
                }
                ForEach(model.settlements) { settlement in
                    HStack {
                        Text(settlementText(settlement))
                        Spacer()
                        Text(settlement.cents.dollars)
                            .bold()
                    }
                    .foregroundStyle(involvesMe(settlement) ? .primary : .secondary)
                }
            }

            // All expenses
            Section("Expenses") {
                if model.expenses.isEmpty {
                    Text("No expenses yet. Add the first one above.")
                        .foregroundStyle(.secondary)
                }
                ForEach(model.expenses) { expense in
                    HStack(spacing: 12) {
                        Image(systemName: expense.category.icon)
                            .frame(width: 28)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(expense.title)
                            Text("Paid by \(name(expense.paidBy)) · split \(expense.splitAmong.count) ways")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(BudgetCalculator.cents(expense.amount).dollars)
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    .swipeActions {
                        if expense.addedBy == auth.userID {
                            Button("Delete", role: .destructive) {
                                model.delete(expense)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(trip: trip) { expense in
                model.add(expense)
            }
        }
        .task {
            guard auth.userID != nil else { return }
            model.start(tripID: trip.id)
        }
        .onDisappear {
            model.stop()
        }
    }

    private func name(_ id: String) -> String {
        id == auth.userID ? "you" : trip.name(for: id)
    }

    private func involvesMe(_ settlement: Settlement) -> Bool {
        settlement.from == auth.userID || settlement.to == auth.userID
    }

    private func settlementText(_ settlement: Settlement) -> String {
        if settlement.from == auth.userID {
            return "You pay \(trip.name(for: settlement.to))"
        }
        return "\(trip.name(for: settlement.from)) pays \(name(settlement.to))"
    }
}