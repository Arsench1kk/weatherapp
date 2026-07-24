#if DEBUG
import Foundation
import CoreLocation

final class DebugLocationManager: LocationManagerProtocol {

    enum Mode {
        case available
        case denied
        case unavailable
    }

    var onLocationUpdate: ((CLLocation) -> Void)?
    var onError: ((LocationError) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?

    private let mode: Mode
    private let location: CLLocation

    init(
        mode: Mode = .available,
        location: CLLocation = CLLocation(
            latitude: DebugWeatherFixtures.almaty.latitude,
            longitude: DebugWeatherFixtures.almaty.longitude
        )
    ) {
        self.mode = mode
        self.location = location
    }

    func requestPermission() {
        startUpdating()
    }

    func startUpdating() {
        switch mode {
        case .available:
            onAuthorizationChange?(.authorizedWhenInUse)
            onLocationUpdate?(location)
        case .denied:
            onAuthorizationChange?(.denied)
            onError?(.permissionDenied)
        case .unavailable:
            onAuthorizationChange?(.authorizedWhenInUse)
            onError?(.locationUnavailable)
        }
    }

    func stopUpdating() {}
}

final class DebugLocationNameResolver: LocationNameResolving {

    private let name: String

    init(name: String = DebugWeatherFixtures.defaultLocationName) {
        self.name = name
    }

    func resolveName(for location: CLLocation) async -> String? {
        name
    }
}
#endif
