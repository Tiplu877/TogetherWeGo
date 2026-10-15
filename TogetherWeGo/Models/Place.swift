//
//  Place.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/15/26.
//

import Foundation
import CoreLocation
import MapKit

struct Place: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var address: String?
    var category: String
    var icon: String
    var latitude: Double
    var longitude: Double
    var phone: String?
    var websiteURL: String?
    var addedBy: String
    var addedByName: String
    var voterIDs: [String] = []      // used in Part 2
    var createdAt: Date = .now

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension MKMapItem {
    // Turns Apple's category into a friendly name and an icon
    var categoryInfo: (name: String, icon: String) {
        switch pointOfInterestCategory {
        case .restaurant?: ("Restaurant", "fork.knife")
        case .cafe?, .bakery?: ("Café", "cup.and.saucer.fill")
        case .museum?: ("Museum", "building.columns.fill")
        case .park?, .nationalPark?: ("Park", "tree.fill")
        case .beach?: ("Beach", "beach.umbrella.fill")
        case .hotel?: ("Hotel", "bed.double.fill")
        case .amusementPark?: ("Amusement Park", "ferriswheel")
        case .nightlife?: ("Nightlife", "music.note")
        case .theater?, .movieTheater?: ("Theater", "theatermasks.fill")
        case .store?: ("Shopping", "bag.fill")
        default: ("Place", "mappin")
        }
    }
}
