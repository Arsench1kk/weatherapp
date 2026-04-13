import Foundation
import CoreLocation

// MARK: - Protocol

protocol LocationManagerProtocol {
    var onLocationUpdate: ((CLLocation) -> Void)? { get set }
    var onError: ((LocationError) -> Void)? { get set }
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)? { get set }
    
    func requestPermission()
    func startUpdating()
    func stopUpdating()
}

// MARK: - Errors

enum LocationError: Error, LocalizedError {
    case permissionDenied
    case permissionRestricted
    case locationUnavailable
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Доступ к геолокации запрещён. Разрешите в настройках"
        case .permissionRestricted:
            return "Использование геолокации ограничено на этом устройстве"
        case .locationUnavailable:
            return "Не удалось определить местоположение"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Implementation

final class LocationManager: NSObject, LocationManagerProtocol {
    
    // MARK: - Callbacks
    
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onError: ((LocationError) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    
    // MARK: - Private
    
    private let manager: CLLocationManager
    private var hasReceivedFirstLocation = false
    
    // MARK: - Init
    
    override init() {
        manager = CLLocationManager()
        super.init()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 1000 // обновлять только при перемещении > 1км
    }
    
    // MARK: - Public Methods
    
    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        case .denied:
            onError?(.permissionDenied)
        case .restricted:
            onError?(.permissionRestricted)
        @unknown default:
            break
        }
    }
    
    func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        onAuthorizationChange?(status)
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        case .denied:
            onError?(.permissionDenied)
        case .restricted:
            onError?(.permissionRestricted)
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Игнорируем устаревшие координаты (старше 30 секунд)
        let age = -location.timestamp.timeIntervalSinceNow
        guard age < 30 else { return }
        
        // Игнорируем неточные координаты
        guard location.horizontalAccuracy > 0, location.horizontalAccuracy < 5000 else { return }
        
        onLocationUpdate?(location)
        
        // Для первого запроса достаточно одного обновления
        if !hasReceivedFirstLocation {
            hasReceivedFirstLocation = true
            stopUpdating()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                onError?(.permissionDenied)
            case .locationUnknown:
                onError?(.locationUnavailable)
            default:
                onError?(.unknown(error))
            }
        } else {
            onError?(.unknown(error))
        }
    }
}
