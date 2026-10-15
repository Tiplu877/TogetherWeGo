//
//  MapSheetItem.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/15/26.
//


import SwiftUI
import MapKit

// What's selected on the map: a search result, or a group pin
enum MapSheetItem: Identifiable {
    case result(MKMapItem)
    case pinned(Place)

    var id: String {
        switch self {
        case .result(let item): "result-\(item.name ?? "")-\(item.placemark.coordinate.latitude)"
        case .pinned(let place): place.id
        }
    }

    var name: String {
        switch self {
        case .result(let item): item.name ?? "Unnamed place"
        case .pinned(let place): place.name
        }
    }

    var address: String? {
        switch self {
        case .result(let item): item.placemark.title
        case .pinned(let place): place.address
        }
    }

    var category: String {
        switch self {
        case .result(let item): item.categoryInfo.name
        case .pinned(let place): place.category
        }
    }

    var icon: String {
        switch self {
        case .result(let item): item.categoryInfo.icon
        case .pinned(let place): place.icon
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .result(let item): item.placemark.coordinate
        case .pinned(let place): place.coordinate
        }
    }

    // Used for "Open in Apple Maps"
    var mapItem: MKMapItem {
        switch self {
        case .result(let item):
            return item
        case .pinned(let place):
            let item = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
            item.name = place.name
            return item
        }
    }
}

struct TripMapView: View {
    @Environment(AuthViewModel.self) private var auth
    let trip: Trip

    @State private var model = MapViewModel()
    @State private var selectionTag: String?
    @State private var sheetItem: MapSheetItem?

    var body: some View {
        Map(position: $model.cameraPosition, selection: $selectionTag) {
            // The group's pins
            ForEach(model.places) { place in
                Marker(place.name, systemImage: place.icon, coordinate: place.coordinate)
                    .tint(.orange)
                    .tag("p:\(place.id)")
            }
            // Search results
            ForEach(Array(model.unpinnedResults.enumerated()), id: \.offset) { index, item in
                Marker(item: item)
                    .tint(.blue)
                    .tag("r:\(index)")
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .safeAreaInset(edge: .top) { searchBar }
        .safeAreaInset(edge: .bottom) { legend }
        .onChange(of: selectionTag) {
            openSheet(for: selectionTag)
        }
        .sheet(item: $sheetItem, onDismiss: { selectionTag = nil }) { item in
            PlaceDetailSheet(item: item,
                             currentUserID: auth.userID,
                             onPin: { mapItem in
                                 guard let userID = auth.userID else { return }
                                 model.pin(mapItem, userID: userID, userName: auth.displayName)
                             },
                             onUnpin: { place in
                                 model.unpin(place)
                             })
                .presentationDetents([.medium, .large])
        }
        .task {
            guard auth.userID != nil else { return }
            await model.start(trip: trip)
        }
        .onDisappear {
            model.stop()
        }
    }

    // MARK: - Pieces

    private var searchBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search near \(trip.destination)", text: $model.searchText)
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await model.search(model.searchText) }
                    }
                if model.isSearching {
                    ProgressView()
                } else if !model.searchResults.isEmpty {
                    Button("Clear") { model.clearResults() }
                        .font(.subheadline)
                }
            }
            .padding(10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MapViewModel.quickSearches, id: \.label) { quick in
                        Button {
                            model.searchText = quick.query
                            Task { await model.search(quick.query) }
                        } label: {
                            Label(quick.label, systemImage: quick.icon)
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .background(.regularMaterial, in: Capsule())
                    }
                }
            }

            if let error = model.errorMessage {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .padding(8)
                    .background(.regularMaterial, in: Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // Color key, so the colors are explained in words too
    private var legend: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle().fill(.orange).frame(width: 10, height: 10)
                Text("Group pins (\(model.places.count))")
            }
            if !model.unpinnedResults.isEmpty {
                HStack(spacing: 6) {
                    Circle().fill(.blue).frame(width: 10, height: 10)
                    Text("Results (\(model.unpinnedResults.count))")
                }
            }
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }

    private func openSheet(for tag: String?) {
        guard let tag else { return }
        if tag.hasPrefix("p:") {
            let id = String(tag.dropFirst(2))
            if let place = model.places.first(where: { $0.id == id }) {
                sheetItem = .pinned(place)
            }
        } else if tag.hasPrefix("r:"), let index = Int(tag.dropFirst(2)),
                  index < model.unpinnedResults.count {
            sheetItem = .result(model.unpinnedResults[index])
        }
    }
}

// The card that slides up when you tap a marker
struct PlaceDetailSheet: View {
    let item: MapSheetItem
    let currentUserID: String?
    let onPin: (MKMapItem) -> Void
    let onUnpin: (Place) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var lookAroundScene: MKLookAroundScene?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Label(item.category, systemImage: item.icon)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(item.name)
                        .font(.title2.bold())
                    if let address = item.address {
                        Text(address)
                            .foregroundStyle(.secondary)
                    }

                    if let scene = lookAroundScene {
                        LookAroundPreview(initialScene: scene)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    switch item {
                    case .result(let mapItem):
                        Button {
                            onPin(mapItem)
                            dismiss()
                        } label: {
                            Label("Pin to Trip", systemImage: "pin.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                    case .pinned(let place):
                        Text(place.addedBy == currentUserID ? "Pinned by you" : "Pinned by \(place.addedByName)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if place.addedBy == currentUserID {
                            Button(role: .destructive) {
                                onUnpin(place)
                                dismiss()
                            } label: {
                                Label("Remove Pin", systemImage: "pin.slash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }

                    Button {
                        _ = item.mapItem.openInMaps()
                    } label: {
                        Label("Open in Apple Maps", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task(id: item.id) {
            lookAroundScene = try? await MKLookAroundSceneRequest(coordinate: item.coordinate).scene
        }
    }
}