import Foundation
import CoreLocation

struct SavedCity: Codable, Equatable {
    let id: String
    let name: String
    let subtitle: String
    let latitude: Double
    let longitude: Double

    init(
        id: String = UUID().uuidString,
        name: String,
        subtitle: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

