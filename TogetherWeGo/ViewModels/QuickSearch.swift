//
//  QuickSearch.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/15/26.
//


import Foundation
import Observation
import SwiftUI
import MapKit
import FirebaseFirestore

struct QuickSearch {
    let label: String
    let query: String
    let icon: String
}

@Observable
class MapViewModel {
    var places: [Place] = []               // the group's pins (Firestore)
    var searchResults: [MKMapItem] = []    // from Apple Maps
    var searchText = ""
    var isSearching = false
    var errorMessage: String?
    var cameraPosition: MapCameraPosition = .automatic

    static let quickSearches = [
        QuickSearch(label: "Food", query: "restaurants", icon: "fork.knife"),
        QuickSearch(label: "Coffee", query: "coffee", icon: "cup.and.saucer.fill"),
        QuickSearch(label: "Sights", query: "tourist attractions", icon: "camera.fill"),
        QuickSearch(label: "Hotels", query: "hotels", icon: "bed.double.fill"),
        QuickSearch(label: "Parks", query: "parks", icon: "tree.fill")
    ]

    private let service = TripService()
    private var listener: ListenerRegistration?
    private var tripID = ""
    private var destination = ""
    private var center: CLLocationCoordinate2D?

    // MARK: - Start / stop

    func start(trip: Trip) async {
        tripID = trip.id
        destination = trip.destination
        listener?.remove()
        listener = service.listenToPlaces(tripID: trip.id) { [weak self] places in
            Task { @MainActor in
                self?.places = places.sorted { $0.createdAt < $1.createdAt }
            }
        }
        if center == nil {
            await locateDestination()
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    // Finds "Orlando, FL" on the map and moves the camera there
    private func locateDestination() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = destination
        do {
            let response = try await MKLocalSearch(request: request).start()
            if let coordinate = response.mapItems.first?.placemark.coordinate {
                center = coordinate
                cameraPosition = .region(MKCoordinateRegion(center: coordinate,
                                                            latitudinalMeters: 15_000,
                                                            longitudinalMeters: 15_000))
            }
        } catch {
            errorMessage = "Couldn't find \(destination) on the map."
        }
    }

    // MARK: - Search

    func search(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {                                   // syntactic
            errorMessage = "Type something to search."
            return
        }
        guard trimmed.count <= 60 else {                                // syntactic
            errorMessage = "Keep your search under 60 characters."
            return
        }
        guard let center else {
            errorMessage = "Still finding \(destination). Try again in a moment."
            return
        }

        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = MKCoordinateRegion(center: center,               // only near the trip
                                            latitudinalMeters: 20_000,
                                            longitudinalMeters: 20_000)
        request.resultTypes = .pointOfInterest

        do {
            let response = try await MKLocalSearch(request: request).start()
            searchResults = Array(response.mapItems.prefix(15))
            if searchResults.isEmpty {
                errorMessage = "No results for \"\(trimmed)\" near \(destination)."
            } else {
                errorMessage = nil
                cameraPosition = .automatic                              // zoom to fit all markers
            }
        } catch {
            errorMessage = "Search failed. Check your connection."
        }
    }

    func clearResults() {
        searchResults = []
        searchText = ""
        errorMessage = nil
        cameraPosition = .automatic
    }

    // MARK: - Pins

    func isPinned(_ item: MKMapItem) -> Bool {
        let c = item.placemark.coordinate
        return places.contains {
            abs($0.latitude - c.latitude) < 0.0002 && abs($0.longitude - c.longitude) < 0.0002
        }
    }

    // Search results that aren't already pinned (so markers don't double up)
    var unpinnedResults: [MKMapItem] {
        searchResults.filter { !isPinned($0) }
    }

    func pin(_ item: MKMapItem, userID: String, userName: String) {
        if isPinned(item) {                                              // semantic
            errorMessage = "That place is already pinned."
            return
        }
        let info = item.categoryInfo
        let coordinate = item.placemark.coordinate
        let place = Place(name: item.name ?? "Unnamed place",
                          address: item.placemark.title,
                          category: info.name,
                          icon: info.icon,
                          latitude: coordinate.latitude,
                          longitude: coordinate.longitude,
                          phone: item.phoneNumber,
                          websiteURL: item.url?.absoluteString,
                          addedBy: userID,
                          addedByName: userName.isEmpty ? "Someone" : userName)
        do {
            try service.addPlace(place, tripID: tripID)
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't pin that place. Try again."
        }
    }

    func unpin(_ place: Place) {
        service.deletePlace(place.id, tripID: tripID)
    }
}
