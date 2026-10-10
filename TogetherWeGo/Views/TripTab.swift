//
//  TripTab.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/4/26.
//


import SwiftUI

enum TripTab: String, CaseIterable, Identifiable {
    case plan = "Plan"
    case budget = "Budget"
    case chat = "Chat"
    case checklist = "Checklist"

    var id: Self { self }
}

struct TripDetailView: View {
    @Environment(TripStore.self) private var store
    let tripID: String

    @State private var selectedTab: TripTab = .checklist
    @State private var copied = false

    // Looked up live, so changes from other phones show up here too
    private var trip: Trip? {
        store.trips.first { $0.id == tripID }
    }

    var body: some View {
        if let trip {
            VStack(spacing: 0) {
                header(for: trip)

                Picker("Section", selection: $selectedTab) {
                    ForEach(TripTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .checklist:
                    ChecklistView(tripID: trip.id)
                case .budget:
                    BudgetView(trip: trip)
                case .plan, .chat:
                    ContentUnavailableView(
                        "Coming soon",
                        systemImage: "hammer",
                        description: Text("We'll build the \(selectedTab.rawValue.lowercased()) tab next.")
                    )
                }
            }
            .navigationTitle(trip.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ShareLink(item: inviteMessage(for: trip)) {
                    Label("Invite", systemImage: "square.and.arrow.up")
                }
            }
        } else {
            ContentUnavailableView("Trip not found", systemImage: "questionmark.folder")
        }
    }

    private func header(for trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(trip.destination, systemImage: "mappin.and.ellipse")
                .font(.title3.bold())
            Label("\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) – \(trip.endDate.formatted(date: .abbreviated, time: .omitted)) · \(trip.lengthInDays) days",
                  systemImage: "calendar")
            Label("\(trip.memberIDs.count) travelers · Budget \(trip.budget.formatted(.currency(code: "USD")))",
                  systemImage: "person.3")
            HStack {
                Text("Join code")
                    .foregroundStyle(.secondary)
                Text(trip.joinCode)
                    .font(.body.monospaced().bold())
                Button(copied ? "Copied!" : "Copy") {
                    UIPasteboard.general.string = trip.joinCode
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        copied = false
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func inviteMessage(for trip: Trip) -> String {
        "Join my trip \"\(trip.name)\" to \(trip.destination) on TogetherWeGo! Open the app, tap + → Join with Code, and enter: \(trip.joinCode)"
    }
}

#Preview {
    NavigationStack {
        TripDetailView(tripID: Trip.samples[0].id)
    }
    .environment(TripStore(trips: Trip.samples))
    .environment(AuthViewModel(loadCurrentUser: false))
}
