#if DEBUG
import Foundation
import CoreLocation

final class DebugCurrentLocationProvider: CurrentLocationProviderProtocol {

    private let mode: DebugLocationManager.Mode
    private let location: CLLocation

    init(
        mode: DebugLocationManager.Mode = .available,
        location: CLLocation = CLLocation(
            latitude: DebugWeatherFixtures.almaty.latitude,
            longitude: DebugWeatherFixtures.almaty.longitude
        )
    ) {
        self.mode = mode
        self.location = location
    }

    @MainActor
    func requestCurrentLocation() async throws -> CLLocation {
        try Task.checkCancellation()

        switch mode {
        case .available:
            return location
        case .denied:
            throw LocationError.permissionDenied
        case .unavailable:
            throw LocationError.locationUnavailable
        }
    }
}
#endif
