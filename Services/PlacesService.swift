import MapKit
import CoreLocation

class PlacesService {

    // MARK: - Search queries per category (cast a wider net)
    private func queries(for category: PlaceCategory) -> [String] {
        switch category {
        case .food:
            return ["restaurant", "fast food", "cafe", "diner", "pizza", "burger", "sandwich", "food"]
        case .gas:
            return ["gas station", "fuel", "shell", "bp", "exxon", "chevron", "mobil", "sunoco", "speedway", "marathon"]
        case .restroom:
            return ["rest area", "rest stop", "welcome center", "truck stop", "travel plaza"]
        }
    }

    // MARK: - Basic nearby search
    func search(category: PlaceCategory,
                near coordinate: CLLocationCoordinate2D,
                radiusMeters: Double = 8000) async -> [MKMapItem] {
        var all: [MKMapItem] = []
        for query in queries(for: category) {
            let results = await runSearch(query: query, coordinate: coordinate, radius: radiusMeters)
            all.append(contentsOf: results)
        }
        return deduplicated(all)
    }

    // MARK: - Route-aware search
    func searchAlongRoute(category: PlaceCategory,
                          route: MKRoute,
                          currentLocation: CLLocation) async -> [MKMapItem] {

        let routeCoords = extractCoordinates(from: route.polyline)
        guard !routeCoords.isEmpty else {
            return await search(category: category, near: currentLocation.coordinate)
        }

        // Find closest point on route to current location
        var closestIndex = 0
        var closestDistance = Double.infinity
        for (i, coord) in routeCoords.enumerated() {
            let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let d = currentLocation.distance(from: loc)
            if d < closestDistance {
                closestDistance = d
                closestIndex = i
            }
        }

        // Sample 4 look-ahead distances: 5km, 10km, 15km, 25km
        let lookAheadDistances: [Double] = [5_000, 10_000, 15_000, 25_000]
        var sampleCoords: [CLLocationCoordinate2D] = [currentLocation.coordinate]

        for target in lookAheadDistances {
            var accumulated = 0.0
            var found = false
            for i in closestIndex..<(routeCoords.count - 1) {
                let a = CLLocation(latitude: routeCoords[i].latitude,   longitude: routeCoords[i].longitude)
                let b = CLLocation(latitude: routeCoords[i+1].latitude, longitude: routeCoords[i+1].longitude)
                accumulated += a.distance(from: b)
                if accumulated >= target {
                    sampleCoords.append(routeCoords[i + 1])
                    found = true
                    break
                }
            }
            // If route is shorter than this look-ahead, add the destination
            if !found, let last = routeCoords.last {
                sampleCoords.append(last)
                break
            }
        }

        // Search at every sample point with every query term, concurrently
        var allResults: [MKMapItem] = []
        await withTaskGroup(of: [MKMapItem].self) { group in
            for coord in sampleCoords {
                for query in queries(for: category) {
                    group.addTask {
                        await self.runSearch(query: query, coordinate: coord, radius: 4000)
                    }
                }
            }
            for await batch in group {
                allResults.append(contentsOf: batch)
            }
        }

        return deduplicated(allResults)
    }

    // MARK: - Private helpers

    private func runSearch(query: String,
                           coordinate: CLLocationCoordinate2D,
                           radius: Double) async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius,
            longitudinalMeters: radius
        )
        request.resultTypes = .pointOfInterest
        guard let response = try? await MKLocalSearch(request: request).start() else { return [] }
        return response.mapItems
    }

    private func extractCoordinates(from polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](
            repeating: kCLLocationCoordinate2DInvalid,
            count: polyline.pointCount
        )
        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: polyline.pointCount))
        return coords
    }

    private func deduplicated(_ items: [MKMapItem]) -> [MKMapItem] {
        var seen = Set<String>()
        var result: [MKMapItem] = []
        for item in items {
            // Use name + approximate coordinate as unique key
            let lat = String(format: "%.4f", item.placemark.coordinate.latitude)
            let lon = String(format: "%.4f", item.placemark.coordinate.longitude)
            let key = "\(item.name ?? "")|\(lat)|\(lon)"
            if !seen.contains(key) {
                seen.insert(key)
                result.append(item)
            }
        }
        return result
    }
}
