//
//  TripState.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import Foundation
import CoreLocation

struct Trip: Codable {
    var id: UUID = UUID()
    var origin: SavedLocation?
    var destination: SavedLocation?
    var passengers: [Passenger] = []
}

struct SavedLocation: Codable {
    var name: String
    var coordinate: CLLocationCoordinate2D

    enum CodingKeys: String, CodingKey {
        case name, latitude, longitude
    }

    init(name: String, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.coordinate = coordinate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        let lat = try c.decode(Double.self, forKey: .latitude)
        let lon = try c.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(coordinate.latitude, forKey: .latitude)
        try c.encode(coordinate.longitude, forKey: .longitude)
    }
}
