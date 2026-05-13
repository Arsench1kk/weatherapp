import Foundation
import CoreLocation

protocol CurrentLocationProviderProtocol {
    func requestCurrentLocation() async throws -> CLLocation
}

final class CurrentLocationProvider: NSObject, CurrentLocationProviderProtocol {

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestCurrentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied:
                finish(with: .failure(LocationError.permissionDenied))
            case .restricted:
                finish(with: .failure(LocationError.permissionRestricted))
            @unknown default:
                finish(with: .failure(LocationError.locationUnavailable))
            }
        }
    }

    private func finish(with result: Result<CLLocation, Error>) {
        guard let continuation else { return }
        self.continuation = nil

        switch result {
        case .success(let location):
            continuation.resume(returning: location)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

extension CurrentLocationProvider: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied:
            finish(with: .failure(LocationError.permissionDenied))
        case .restricted:
            finish(with: .failure(LocationError.permissionRestricted))
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finish(with: .failure(LocationError.locationUnavailable))
            return
        }

        finish(with: .success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .denied {
            finish(with: .failure(LocationError.permissionDenied))
        } else {
            finish(with: .failure(LocationError.unknown(error)))
        }
    }
}

