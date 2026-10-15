//
//  TripStoryCard.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/13/26.
//


import SwiftUI

struct TripStoryCard: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("TogetherWeGo", systemImage: "airplane")
                .font(.subheadline.bold())
                .opacity(0.9)

            Spacer(minLength: 0)

            Text(trip.name)
                .font(.system(size: 34, weight: .heavy))
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            Label(trip.destination, systemImage: "mappin.and.ellipse")
                .font(.title3.weight(.semibold))

            Text("\(trip.startDate.formatted(.dateTime.month(.abbreviated).day())) – \(trip.endDate.formatted(.dateTime.month(.abbreviated).day().year()))")
                .font(.headline)
                .opacity(0.9)

            HStack(spacing: 10) {
                stat("\(trip.memberIDs.count)", "travelers")
                stat("\(trip.lengthInDays)", "days")
            }

            Text("Planned together on TogetherWeGo")
                .font(.caption.weight(.medium))
                .opacity(0.8)
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(width: 320, height: 420, alignment: .leading)
        .background(
            LinearGradient(colors: [Color(red: 0.12, green: 0.23, blue: 0.54),
                                    Color(red: 0.98, green: 0.45, blue: 0.09)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28)
        )
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.title.bold())
            Text(label).font(.caption)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    TripStoryCard(trip: Trip.samples[0])
}