import Foundation
import CoreLocation

final class MainViewModel {
    
    // MARK: - Callbacks для ViewController
    
    var onWeatherLoaded: ((WeatherResponse) -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    
    // MARK: - Private
    
    private let getWeatherUseCase: GetWeatherUseCaseProtocol
    private var locationManager: LocationManagerProtocol
    
    // MARK: - Init
    
    init(
        getWeatherUseCase: GetWeatherUseCaseProtocol,
        locationManager: LocationManagerProtocol
    ) {
        self.getWeatherUseCase = getWeatherUseCase
        self.locationManager = locationManager
        
        setupLocationCallbacks()
    }
    
    // MARK: - Public
    
    func viewDidLoad() {
        locationManager.requestPermission()
    }
    
    // MARK: - Private
    
    private func setupLocationCallbacks() {
        locationManager.onLocationUpdate = { [weak self] location in
            self?.fetchWeather(for: location)
        }
        
        locationManager.onError = { [weak self] error in
            self?.onError?(error.localizedDescription ?? "Ошибка геолокации")
        }
    }
    
    private func fetchWeather(for location: CLLocation) {
        onLoadingStateChanged?(true)
        
        Task { [weak self] in
            guard let self else { return }
            
            do {
                let weather = try await self.getWeatherUseCase.execute(for: location)
                
                // Логируем в консоль (требование задания)
                self.logWeatherData(weather)
                
                await MainActor.run {
                    self.onLoadingStateChanged?(false)
                    self.onWeatherLoaded?(weather)
                }
            } catch {
                await MainActor.run {
                    self.onLoadingStateChanged?(false)
                    let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                    self.onError?(message)
                }
            }
        }
    }
    
    private func logWeatherData(_ weather: WeatherResponse) {
        print("╔══════════════════════════════════════╗")
        print("║          WEATHER DATA LOADED         ║")
        print("╠══════════════════════════════════════╣")
        print("║ City:        \(weather.name)")
        print("║ Temp:        \(Int(weather.main.temp))°C")
        print("║ Feels like:  \(Int(weather.main.feelsLike))°C")
        print("║ Min/Max:     \(Int(weather.main.tempMin))° / \(Int(weather.main.tempMax))°")
        print("║ Condition:   \(weather.weather.first?.description ?? "—")")
        print("║ Humidity:    \(weather.main.humidity)%")
        print("║ Wind speed:  \(weather.wind.speed) m/s")
        print("║ Pressure:    \(weather.main.pressure) hPa")
        print("║ Coordinates: \(weather.coord.lat), \(weather.coord.lon)")
        print("╚══════════════════════════════════════╝")
    }
}
