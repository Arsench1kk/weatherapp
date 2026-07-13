import Foundation
import CoreLocation

final class MainViewModel {

    // MARK: - Callback для ViewController

    var onStateChanged: ((MainScreenState) -> Void)?

    // MARK: - Dependencies

    private let getWeatherUseCase: GetWeatherUseCaseProtocol
    private var locationManager: LocationManagerProtocol
    private let locationNameResolver: LocationNameResolving
    private var weatherTask: Task<Void, Never>?
    private let fallbackLocationName = "Текущее местоположение"

    // MARK: - Init

    init(
        getWeatherUseCase: GetWeatherUseCaseProtocol,
        locationManager: LocationManagerProtocol,
        locationNameResolver: LocationNameResolving
    ) {
        self.getWeatherUseCase = getWeatherUseCase
        self.locationManager = locationManager
        self.locationNameResolver = locationNameResolver
        setupLocationCallbacks()
    }

    deinit {
        weatherTask?.cancel()
    }

    // MARK: - Public Interface

    func viewDidLoad() {
        fetchWeather()
    }

    func refresh() {
        // Pull-to-refresh — не показываем .loading, данные уже есть
        fetchWeather(showLoading: false)
    }

    // MARK: - Private

    private func fetchWeather(showLoading: Bool = true) {
        weatherTask?.cancel()

        if showLoading {
            onStateChanged?(.loading)
        }

        locationManager.requestPermission()
    }

    private func setupLocationCallbacks() {
        locationManager.onLocationUpdate = { [weak self] location in
            Task { @MainActor in
                self?.loadWeather(for: location)
            }
        }

        locationManager.onError = { [weak self] error in
            Task { @MainActor in
                let message = error.errorDescription ?? "Ошибка геолокации"
                self?.onStateChanged?(.error(message))
            }
        }
    }

    private func loadWeather(for location: CLLocation) {
        weatherTask?.cancel()

        weatherTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                async let resolvedLocationName = self.locationNameResolver.resolveName(for: location)
                let response = try await self.getWeatherUseCase.execute(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude
                )
                guard !Task.isCancelled else { return }

                let locationName = await resolvedLocationName ?? self.fallbackLocationName
                let uiModel = WeatherMapper.map(response: response, locationName: locationName)
                self.onStateChanged?(.loaded(uiModel))
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                let message = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
                self.onStateChanged?(.error(message))
            }
        }
    }
}
