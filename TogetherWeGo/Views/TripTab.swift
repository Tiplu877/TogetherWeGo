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
    @Environment(\.openURL) private var openURL
    let tripID: String

    @State private var selectedTab: TripTab = .plan
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
                case .plan:
                    PlanView(trip: trip)
                case .budget:
                    BudgetView(trip: trip)
                case .chat:
                    ChatView(tripID: trip.id)
                case .checklist:
                    ChecklistView(tripID: trip.id)
                }
            }
            .navigationTitle(trip.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Menu {
                    ShareLink(item: trip.inviteURL, message: Text(trip.inviteMessage)) {
                        Label("Share…", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        open("sms:&body=\(encoded(trip.inviteMessage))")
                    } label: {
                        Label("Text Message", systemImage: "message.fill")
                    }
                    Button {
                        open("https://wa.me/?text=\(encoded(trip.inviteMessage))")
                    } label: {
                        Label("WhatsApp", systemImage: "phone.bubble.fill")
                    }
                } label: {
                    Label("Invite", systemImage: "person.badge.plus")
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

    // Makes text safe to put inside a link (spaces → %20, etc.)
    private func encoded(_ text: String) -> String {
        text.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
    }

    private func open(_ address: String) {
        if let url = URL(string: address) {
            openURL(url)
        }
    }}

#Preview {
    NavigationStack {
        TripDetailView(tripID: Trip.samples[0].id)
    }
    .environment(TripStore(trips: Trip.samples))
    .environment(AuthViewModel(loadCurrentUser: false))
}
