
import Foundation
import CoreLocation
import MapKit

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension MKRoute {
    var distanceMiles: Double { distance / 1609.34 }
    var etaMinutes: Double    { expectedTravelTime / 60 }
}

extension Double {
    var asDistanceString: String {
        self < 0.1
            ? String(format: "%.0f ft", self * 5280)
            : String(format: "%.1f mi", self)
    }
}
