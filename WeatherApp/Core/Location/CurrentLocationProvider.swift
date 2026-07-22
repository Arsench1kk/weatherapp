import Foundation
import CoreLocation

protocol CurrentLocationProviderProtocol {
    @MainActor
    func requestCurrentLocation() async throws -> CLLocation
}

final class CurrentLocationProvider: NSObject, CurrentLocationProviderProtocol {

    private let manager = CLLocationManager()
    private struct LocationRequest {
        let id: UUID
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
        let requestID = UUID()

        let provider = self

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                finishCurrentRequest(with: .failure(CancellationError()))
                currentRequest = LocationRequest(id: requestID, continuation: continuation)

                if Task.isCancelled {
                    finishRequest(id: requestID, with: .failure(CancellationError()))
                    return
                }

                startRequest(for: requestID)
            }
        } onCancel: {
            Task { @MainActor in
                provider.cancelRequest(id: requestID)
            }
        }
    }

    @MainActor
    private func startRequest(for requestID: UUID) {
        guard currentRequest?.id == requestID else { return }

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied:
            finishRequest(id: requestID, with: .failure(LocationError.permissionDenied))
        case .restricted:
            finishRequest(id: requestID, with: .failure(LocationError.permissionRestricted))
        @unknown default:
            finishRequest(id: requestID, with: .failure(LocationError.locationUnavailable))
        }
    }

    @MainActor
    private func cancelRequest(id requestID: UUID) {
        finishRequest(id: requestID, with: .failure(CancellationError()))
    }

    @MainActor
    private func finishRequest(id requestID: UUID, with result: Result<CLLocation, Error>) {
        guard currentRequest?.id == requestID else { return }
        finishCurrentRequest(with: result)
    }

    @MainActor
    private func finishCurrentRequest(with result: Result<CLLocation, Error>) {
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
            guard let requestID = currentRequest?.id else { return }

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied:
                finishRequest(id: requestID, with: .failure(LocationError.permissionDenied))
            case .restricted:
                finishRequest(id: requestID, with: .failure(LocationError.permissionRestricted))
            default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let requestID = currentRequest?.id else { return }

            guard let location = locations.last else {
                finishRequest(id: requestID, with: .failure(LocationError.locationUnavailable))
                return
            }

            finishRequest(id: requestID, with: .success(location))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let requestID = currentRequest?.id else { return }

            if let clError = error as? CLError, clError.code == .denied {
                finishRequest(id: requestID, with: .failure(LocationError.permissionDenied))
            } else {
                finishRequest(id: requestID, with: .failure(LocationError.unknown(error)))
            }
        }
    }
}
