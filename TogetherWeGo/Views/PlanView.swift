//
//  PlanView.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/11/26.
//


import SwiftUI

struct PlanView: View {
    @Environment(AuthViewModel.self) private var auth
    let trip: Trip

    @State private var model = PlanViewModel()
    @State private var selectedDay: Date?
    @State private var showingAddActivity = false

    // Opens on today if the trip is happening now, otherwise Day 1
    private var defaultDay: Date {
        let today = Calendar.current.startOfDay(for: .now)
        return trip.days.contains(today) ? today : (trip.days.first ?? today)
    }

    private var day: Date { selectedDay ?? defaultDay }

    var body: some View {
        VStack(spacing: 0) {
            dayPicker

            List {
                let schedule = model.schedule(for: day)

                if schedule.isEmpty {
                    ContentUnavailableView(
                        "Nothing planned yet",
                        systemImage: "calendar.badge.plus",
                        description: Text("Add the first activity for this day.")
                    )
                    .listRowBackground(Color.clear)
                }

                ForEach(schedule) { activity in
                    ActivityRow(activity: activity,
                                addedByText: activity.addedBy == auth.userID ? "Added by you" : "Added by \(activity.addedByName)")
                        .swipeActions {
                            if activity.addedBy == auth.userID {
                                Button("Delete", role: .destructive) {
                                    model.delete(activity)
                                }
                            }
                        }
                }

                Button {
                    showingAddActivity = true
                } label: {
                    Label("Add Activity", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddActivity) {
            AddActivityView(trip: trip, day: day, existing: model.activities) { activity in
                model.add(activity)
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

    // Horizontal row of "Day 1 / Day 2 / ..." chips
    private var dayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(trip.days.enumerated()), id: \.element) { index, date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: day)
                    let count = model.schedule(for: date).count

                    Button {
                        selectedDay = date
                    } label: {
                        VStack(spacing: 2) {
                            Text("Day \(index + 1)")
                                .font(.caption.bold())
                            Text(date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                                .font(.caption2)
                            Text(count == 0 ? " " : "\(count) planned")
                                .font(.caption2)
                                .opacity(0.8)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Day \(index + 1), \(date.formatted(date: .complete, time: .omitted)), \(count) activities")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// One activity in the schedule
struct ActivityRow: View {
    let activity: Activity
    let addedByText: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline.bold())
                if let end = activity.endTime {
                    Text(end.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 72, alignment: .trailing)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.accentColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.headline)
                if let place = activity.placeName {
                    Label(place, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let notes = activity.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(addedByText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}