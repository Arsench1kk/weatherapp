import Foundation
import CoreLocation

protocol CurrentLocationProviderProtocol {
    @MainActor
    func requestCurrentLocation() async throws -> CLLocation
}

final class CurrentLocationProvider: NSObject, CurrentLocationProviderProtocol {

    private let manager = CLLocationManager()

    private struct RequestToken: Equatable, Sendable {
        let id = UUID()
    }

    private struct LocationRequest {
        let token: RequestToken
        let continuation: CheckedContinuation<CLLocation, Error>
    }

    private var currentRequest: LocationRequest?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    @MainActor
    func requestCurrentLocation() async throws -> CLLocation {
        try Task.checkCancellation()
        let token = RequestToken()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                cancelActiveRequest()
                currentRequest = LocationRequest(token: token, continuation: continuation)

                if Task.isCancelled {
                    finishRequest(token: token, with: .failure(CancellationError()))
                    return
                }

                startRequest(for: token)
            }
        } onCancel: {
            Task { @MainActor [weak self, token] in
                self?.cancelRequest(token: token)
            }
        }
    }

    @MainActor
    private func startRequest(for token: RequestToken) {
        guard currentRequest?.token == token else { return }

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied:
            finishRequest(token: token, with: .failure(LocationError.permissionDenied))
        case .restricted:
            finishRequest(token: token, with: .failure(LocationError.permissionRestricted))
        @unknown default:
            finishRequest(token: token, with: .failure(LocationError.locationUnavailable))
        }
    }

    @MainActor
    private func cancelRequest(token: RequestToken) {
        finishRequest(token: token, with: .failure(CancellationError()))
    }

    @MainActor
    private func finishRequest(token: RequestToken, with result: Result<CLLocation, Error>) {
        guard currentRequest?.token == token else { return }
        finishActiveRequest(with: result)
    }

    @MainActor
    private func cancelActiveRequest() {
        finishActiveRequest(with: .failure(CancellationError()))
    }

    @MainActor
    private func finishActiveRequest(with result: Result<CLLocation, Error>) {
        guard let request = currentRequest else { return }
        currentRequest = nil

        switch result {
        case .success(let location):
            request.continuation.resume(returning: location)
        case .failure(let error):
            request.continuation.resume(throwing: error)
        }
    }
}

extension CurrentLocationProvider: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let token = currentRequest?.token else { return }

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied:
                finishRequest(token: token, with: .failure(LocationError.permissionDenied))
            case .restricted:
                finishRequest(token: token, with: .failure(LocationError.permissionRestricted))
            default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let token = currentRequest?.token else { return }

            guard let location = locations.last else {
                finishRequest(token: token, with: .failure(LocationError.locationUnavailable))
                return
            }

            finishRequest(token: token, with: .success(location))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let token = currentRequest?.token else { return }

            if let clError = error as? CLError, clError.code == .denied {
                finishRequest(token: token, with: .failure(LocationError.permissionDenied))
            } else {
                finishRequest(token: token, with: .failure(LocationError.unknown(error)))
            }
        }
    }
}
