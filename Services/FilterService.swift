import Foundation
import MapKit
import CoreLocation

// MARK: - Chain Dietary Profile

struct ChainDietaryProfile {
    var isVeganFriendly        = false
    var isVegetarianFriendly   = false
    var hasGlutenFreeOptions   = false
    var hasDairyFreeOptions    = false
    var isKetoFriendly         = false
    var isHalal                = false
    var isKosher               = false
    var hasNoVeganOptions      = false
    var hasNoVegetarianOptions = false
    var containsNuts           = false
    var containsShellfish      = false
}

// MARK: - Chain Dietary Data

struct ChainDietaryData {
    static func profile(for nameLower: String) -> ChainDietaryProfile {
        var p = ChainDietaryProfile()

        if nameLower.contains("mcdonald") {
            p.isVegetarianFriendly = true
            p.isKetoFriendly = true

        } else if nameLower.contains("burger king") {
            p.isVegetarianFriendly = true
            p.isVeganFriendly = true
            p.isKetoFriendly = true

        } else if nameLower.contains("wendy") {
            p.isVegetarianFriendly = true
            p.hasGlutenFreeOptions = true
            p.isKetoFriendly = true

        } else if nameLower.contains("chick-fil") || nameLower.contains("chickfil") {
            p.hasGlutenFreeOptions = true
            p.isKetoFriendly = true

        } else if nameLower.contains("taco bell") {
            p.isVegetarianFriendly = true
            p.isVeganFriendly = true

        } else if nameLower.contains("subway") {
            p.isVegetarianFriendly = true
            p.isVeganFriendly = true
            p.hasGlutenFreeOptions = true
            p.hasDairyFreeOptions = true

        } else if nameLower.contains("chipotle") {
            p.isVeganFriendly = true
            p.isVegetarianFriendly = true
            p.hasGlutenFreeOptions = true
            p.hasDairyFreeOptions = true
            p.isKetoFriendly = true

        } else if nameLower.contains("panera") {
            p.isVeganFriendly = true
            p.isVegetarianFriendly = true
            p.hasGlutenFreeOptions = true
            p.hasDairyFreeOptions = true

        } else if nameLower.contains("starbucks") {
            p.isVeganFriendly = true
            p.isVegetarianFriendly = true
            p.hasGlutenFreeOptions = true
            p.hasDairyFreeOptions = true

        } else if nameLower.contains("dunkin") {
            p.isVegetarianFriendly = true
            p.hasDairyFreeOptions = true

        } else if nameLower.contains("pizza hut") || nameLower.contains("domino") {
            p.isVegetarianFriendly = true
            p.hasGlutenFreeOptions = true

        } else if nameLower.contains("papa john") {
            p.isVegetarianFriendly = true
            p.hasGlutenFreeOptions = true

        } else if nameLower.contains("five guys") {
            p.isVegetarianFriendly = true
            p.containsNuts = true

        } else if nameLower.contains("shake shack") {
            p.isVegetarianFriendly = true
            p.isKetoFriendly = true

        } else if nameLower.contains("in-n-out") {
            p.isVegetarianFriendly = true
            p.isKetoFriendly = true
            p.hasGlutenFreeOptions = true

        } else if nameLower.contains("whataburger") {
            p.isKetoFriendly = true

        } else if nameLower.contains("dairy queen") || nameLower.contains(" dq") {
            p.isVegetarianFriendly = true
            p.containsNuts = true

        } else if nameLower.contains("olive garden") {
            p.isVegetarianFriendly = true
            p.hasGlutenFreeOptions = true

        } else if nameLower.contains("applebee") {
            p.isVegetarianFriendly = true
            p.hasGlutenFreeOptions = true
            p.isKetoFriendly = true

        } else if nameLower.contains("chilis") || nameLower.contains("chili's") {
            p.isVegetarianFriendly = true
            p.hasGlutenFreeOptions = true

        } else if nameLower.contains("denny") {
            p.isVegetarianFriendly = true

        } else if nameLower.contains("ihop") {
            p.isVegetarianFriendly = true

        } else if nameLower.contains("cracker barrel") {
            p.isVegetarianFriendly = true
            p.hasGlutenFreeOptions = true

        } else if nameLower.contains("waffle house") {
            p.isVegetarianFriendly = true

        } else if nameLower.contains("red lobster") {
            p.containsShellfish = true
            p.hasGlutenFreeOptions = true

        } else if nameLower.contains("longhorn") || nameLower.contains("outback") ||
                  nameLower.contains("texas roadhouse") {
            p.isVegetarianFriendly = true
            p.hasGlutenFreeOptions = true
            p.isKetoFriendly = true

        } else if nameLower.contains("sweetgreen") {
            p.isVeganFriendly = true
            p.isVegetarianFriendly = true
            p.hasGlutenFreeOptions = true
            p.hasDairyFreeOptions = true
            p.isKetoFriendly = true

        } else if nameLower.contains("cava") {
            p.isVeganFriendly = true
            p.isVegetarianFriendly = true
            p.hasGlutenFreeOptions = true
            p.hasDairyFreeOptions = true
            p.isHalal = true
        }

        return p
    }
}

// MARK: - FilterService

class FilterService {

    private let maxRouteDistanceMeters: Double = 1609

    // MARK: - Route proximity

    func filterByRouteProximity(items: [MKMapItem], route: MKRoute) -> [MKMapItem] {
        let routeCoords = extractCoordinates(from: route.polyline)
        guard !routeCoords.isEmpty else { return items }

        return items.filter { item in
            guard let itemLocation = item.placemark.location else { return false }
            return routeCoords.contains { coord in
                let routePoint = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                return itemLocation.distance(from: routePoint) <= maxRouteDistanceMeters
            }
        }
    }

    // MARK: - Food scoring

    func score(places: [MKMapItem],
               for passengers: [Passenger],
               currentLocation: CLLocation?,
               route: MKRoute? = nil) -> [PlaceResult] {

        let proximityFiltered: [MKMapItem]
        if let route = route {
            proximityFiltered = filterByRouteProximity(items: places, route: route)
        } else {
            proximityFiltered = places
        }

        let allAllergens: Set<Allergen> = passengers
            .flatMap { Array($0.dietaryProfile.allergens) }
            .reduce(into: []) { $0.insert($1) }

        let allRestrictions: Set<DietaryRestriction> = passengers
            .flatMap { Array($0.dietaryProfile.restrictions) }
            .reduce(into: []) { $0.insert($1) }

        var cuisineVotes: [CuisinePreference: Int] = [:]
        for p in passengers {
            for c in p.dietaryProfile.cuisinePreferences {
                cuisineVotes[c, default: 0] += 1
            }
        }
        let topCuisines = cuisineVotes.sorted { $0.value > $1.value }.prefix(3).map(\.key)

        return proximityFiltered.compactMap { item -> PlaceResult? in
            guard let name = item.name else { return nil }
            let nameLower = name.lowercased()
            let poiCategory = item.pointOfInterestCategory
            let chainProfile = ChainDietaryData.profile(for: nameLower)

            var warnings: [String] = []
            var notes: [String] = []
            var score = 0.5
            var hardFail = false

            // Hard exclusion: bars for halal
            let isBar = poiCategory == .nightlife ||
                        nameLower.contains("bar ") ||
                        nameLower.contains("brewery") ||
                        nameLower.contains("pub")
            if isBar && allRestrictions.contains(.halal) {
                hardFail = true
            }

            // Vegan
            if allRestrictions.contains(.vegan) {
                if chainProfile.isVeganFriendly || nameLower.contains("vegan") || nameLower.contains("plant") {
                    score += 0.25; notes.append("Vegan-friendly")
                } else if chainProfile.hasNoVeganOptions {
                    hardFail = true
                } else {
                    score -= 0.1; warnings.append("Vegan options may be limited")
                }
            }

            // Vegetarian
            if allRestrictions.contains(.vegetarian) {
                if chainProfile.isVegetarianFriendly ||
                    nameLower.contains("veggie") || nameLower.contains("garden") {
                    score += 0.15; notes.append("Vegetarian-friendly")
                } else if chainProfile.hasNoVegetarianOptions {
                    score -= 0.2; warnings.append("Limited vegetarian options")
                } else {
                    warnings.append("Confirm vegetarian options")
                }
            }

            // Halal
            if allRestrictions.contains(.halal) {
                if chainProfile.isHalal || nameLower.contains("halal") {
                    score += 0.3; notes.append("Halal certified")
                } else {
                    score -= 0.25; warnings.append("⚠️ Halal status unconfirmed")
                }
            }

            // Kosher
            if allRestrictions.contains(.kosher) {
                if chainProfile.isKosher || nameLower.contains("kosher") {
                    score += 0.3; notes.append("Kosher certified")
                } else {
                    score -= 0.25; warnings.append("⚠️ Kosher status unconfirmed")
                }
            }

            // Gluten-free
            if allRestrictions.contains(.glutenFree) {
                if chainProfile.hasGlutenFreeOptions || nameLower.contains("gluten") {
                    score += 0.1; notes.append("Gluten-free options available")
                } else {
                    warnings.append("Ask about gluten-free options")
                }
            }

            // Dairy-free
            if allRestrictions.contains(.dairyFree) {
                if chainProfile.hasDairyFreeOptions {
                    score += 0.1; notes.append("Dairy-free options available")
                } else {
                    warnings.append("Ask about dairy-free options")
                }
            }

            // Keto / low carb
            if allRestrictions.contains(.keto) || allRestrictions.contains(.lowCarb) {
                if chainProfile.isKetoFriendly {
                    score += 0.1; notes.append("Keto-friendly options")
                } else {
                    warnings.append("Limited low-carb options")
                }
            }

            // Nut allergy
            if allAllergens.contains(.nuts) || allAllergens.contains(.peanuts) {
                if chainProfile.containsNuts {
                    hardFail = true
                } else {
                    warnings.append("⚠️ Nut allergy — verify with staff")
                }
            }

            // Shellfish allergy (FIXED: Removed non-existent .seafood enum)
            if allAllergens.contains(.shellfish) {
                let isSeafoodVenue = nameLower.contains("seafood") || nameLower.contains("crab") ||
                    nameLower.contains("lobster") || nameLower.contains("shrimp")
                if isSeafoodVenue || chainProfile.containsShellfish {
                    hardFail = true
                } else {
                    warnings.append("⚠️ Shellfish risk — verify menu")
                }
            }

            // Gluten allergen
            if allAllergens.contains(.gluten) {
                if chainProfile.hasGlutenFreeOptions {
                    notes.append("Gluten-free options available")
                } else {
                    warnings.append("⚠️ Gluten allergy — verify with staff")
                }
            }

            // Dairy allergen
            if allAllergens.contains(.dairy) {
                if chainProfile.hasDairyFreeOptions {
                    notes.append("Dairy-free options available")
                } else {
                    warnings.append("Ask about dairy-free alternatives")
                }
            }

            if allAllergens.contains(.eggs) {
                warnings.append("Egg allergy — check menu carefully")
            }

            if allAllergens.contains(.soy) {
                warnings.append("Soy allergy — verify with staff")
            }

            // Cuisine preference bonus
            for cuisine in topCuisines {
                if cuisineKeywords(cuisine).contains(where: { nameLower.contains($0) }) {
                    score += 0.15
                    notes.append("Matches \(cuisine.displayName) preference")
                    break
                }
            }

            // POI category bonus
            if poiCategory == .restaurant { score += 0.1 }
            else if poiCategory == .cafe  { score += 0.05 }

            guard !hardFail else { return nil }
            score = max(0, min(1, score))

            var distanceMiles = 0.0
            if let loc = currentLocation, let itemLoc = item.placemark.location {
                distanceMiles = loc.distance(from: itemLoc) / 1609.34
            }

            return PlaceResult(
                mapItem: item,
                category: .food,
                distanceMiles: distanceMiles,
                compatibilityScore: score,
                compatibilityNotes: notes,
                warnings: warnings
            )
        }
        .sorted { $0.compatibilityScore > $1.compatibilityScore }
    }

    // MARK: - Gas station filter

    func filterGasStations(items: [MKMapItem],
                           currentLocation: CLLocation?,
                           route: MKRoute?) -> [PlaceResult] {
        let proximityFiltered: [MKMapItem]
        if let route = route {
            proximityFiltered = filterByRouteProximity(items: items, route: route)
        } else {
            proximityFiltered = items
        }

        let gasKeywords = ["gas", "fuel", "shell", "bp", "exxon", "chevron", "mobil",
                           "sunoco", "speedway", "marathon", "citgo", "valero",
                           "kwik", "wawa", "pilot", "loves", "casey", "circle k",
                           "quiktrip", "qt ", "racetrac", "murphy", "amoco", "76",
                           "texaco", "conoco", "phillips", "petro", "flying j"]

        return proximityFiltered.compactMap { item -> PlaceResult? in
            guard let name = item.name else { return nil }
            let nameLower = name.lowercased()
            let isGasStation = item.pointOfInterestCategory == .gasStation ||
                               gasKeywords.contains(where: { nameLower.contains($0) })
            guard isGasStation else { return nil }

            var distanceMiles = 0.0
            if let loc = currentLocation, let itemLoc = item.placemark.location {
                distanceMiles = loc.distance(from: itemLoc) / 1609.34
            }

            return PlaceResult(
                mapItem: item,
                category: .gas,
                distanceMiles: distanceMiles,
                compatibilityScore: 1.0,
                compatibilityNotes: [],
                warnings: []
            )
        }
        .sorted { $0.distanceMiles < $1.distanceMiles }
    }

    // MARK: - Restroom filter

    func filterRestrooms(items: [MKMapItem],
                         currentLocation: CLLocation?,
                         route: MKRoute?) -> [PlaceResult] {
        let proximityFiltered: [MKMapItem]
        if let route = route {
            proximityFiltered = filterByRouteProximity(items: items, route: route)
        } else {
            proximityFiltered = items
        }

        let restroomKeywords = [
            "rest area", "rest stop", "welcome center", "travel plaza", "service plaza",
            "truck stop", "travel center", "truckstop",
            "wawa", "buc-ee", "bucee", "pilot", "loves", "flying j", "petro",
            "kwiktrip", "kwik trip", "sheetz", "quiktrip",
            "mcdonald", "wendy", "burger king", "chick-fil", "taco bell",
            "subway", "popeyes", "sonic", "arbys", "arby's",
            "walmart", "target", "cracker barrel"
        ]

        return proximityFiltered.compactMap { item -> PlaceResult? in
            guard let name = item.name else { return nil }
            let nameLower = name.lowercased()
            let poiCategory = item.pointOfInterestCategory

            // FIXED: Removed non-existent .fastFood enum. Fast food falls under .restaurant in MapKit.
            let isValidVenue =
                restroomKeywords.contains(where: { nameLower.contains($0) }) ||
                poiCategory == .restroom ||
                poiCategory == .gasStation ||
                poiCategory == .restaurant ||
                poiCategory == .cafe

            guard isValidVenue else { return nil }

            var notes: [String] = []
            if nameLower.contains("rest area") || nameLower.contains("welcome center") ||
               nameLower.contains("travel plaza") || nameLower.contains("service plaza") {
                notes.append("Dedicated rest area")
            } else if nameLower.contains("wawa") || nameLower.contains("buc-ee") ||
                      nameLower.contains("sheetz") || nameLower.contains("kwiktrip") {
                notes.append("Clean facilities")
            } else if poiCategory == .gasStation {
                notes.append("Gas station — restroom available")
            } else if poiCategory == .restaurant {
                notes.append("Restaurant — purchase may be required")
            }

            var distanceMiles = 0.0
            if let loc = currentLocation, let itemLoc = item.placemark.location {
                distanceMiles = loc.distance(from: itemLoc) / 1609.34
            }

            return PlaceResult(
                mapItem: item,
                category: .restroom,
                distanceMiles: distanceMiles,
                compatibilityScore: 1.0,
                compatibilityNotes: notes,
                warnings: []
            )
        }
        .sorted { $0.distanceMiles < $1.distanceMiles }
    }

    // MARK: - Private helpers

    private func extractCoordinates(from polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        let stride = max(1, polyline.pointCount / 300)
        var allCoords = [CLLocationCoordinate2D](
            repeating: kCLLocationCoordinate2DInvalid,
            count: polyline.pointCount
        )
        polyline.getCoordinates(&allCoords, range: NSRange(location: 0, length: polyline.pointCount))
        return allCoords.enumerated()
            .filter { $0.offset % stride == 0 }
            .map(\.element)
    }

    private func cuisineKeywords(_ cuisine: CuisinePreference) -> [String] {
        switch cuisine {
        case .american:      return ["diner", "american", "grill", "smokehouse"]
        case .mexican:       return ["mexican", "taco", "burrito", "cantina", "tex-mex"]
        case .italian:       return ["italian", "pizza", "pasta", "trattoria"]
        case .asian:         return ["asian", "chinese", "japanese", "thai", "sushi", "ramen", "pho"]
        case .mediterranean: return ["mediterranean", "greek", "falafel", "hummus", "shawarma"]
        case .fastFood:      return ["mcdonald", "burger king", "wendy", "chick-fil", "subway", "taco bell"]
        case .pizza:         return ["pizza", "pizzeria"]
        case .burgers:       return ["burger", "smash", "five guys", "shake shack"]
        case .salads:        return ["salad", "sweetgreen", "chopt"]
        case .bbq:           return ["bbq", "barbeque", "barbecue", "smokehouse"]
        }
    }
}
