//
//  Constants.swift
//  MegaRoadTripApp
//
//  Created by Liam Riedy on 6/26/26.
//

import Foundation

enum Constants {
    enum Search {
        static let defaultRadiusMeters: Double = 8_000
        static let exitLookAheadMeters: Double = 15_000
        static let maxSuggestions     = 6
        static let maxResults         = 10
    }

    enum Map {
        static let routePaddingFactor = 0.15
    }
}
