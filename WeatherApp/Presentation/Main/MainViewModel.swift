import Foundation
import CoreLocation

final class MainViewModel {

    // MARK: - Callback для ViewController

    var onStateChanged: ((MainScreenState) -> Void)?

    // MARK: - Dependencies

    private let getWeatherUseCase: GetWeatherUseCaseProtocol
    private let getForecastUseCase: GetForecastUseCaseProtocol
    private var locationManager: LocationManagerProtocol

    // MARK: - Init

    init(
        getWeatherUseCase: GetWeatherUseCaseProtocol,
        getForecastUseCase: GetForecastUseCaseProtocol,
        locationManager: LocationManagerProtocol
    ) {
        self.getWeatherUseCase = getWeatherUseCase
        self.getForecastUseCase = getForecastUseCase
        self.locationManager = locationManager
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
        if showLoading {
            onStateChanged?(.loading)
        }

        locationManager.requestPermission()

        locationManager.onLocationUpdate = { [weak self] location in
            guard let self else { return }

            Task { @MainActor in
                do {
                    // Запускаем оба запроса параллельно через async let
                    async let current = self.getWeatherUseCase.execute(
                        lat: location.coordinate.latitude,
                        lon: location.coordinate.longitude
                    )

                    async let forecast = self.getForecastUseCase.execute(
                        lat: location.coordinate.latitude,
                        lon: location.coordinate.longitude
                    )

                    // Ждём оба результата
                    let (currentResult, forecastResult) = try await (current, forecast)

                    // Маппим в UI-модель
                    let uiModel = WeatherMapper.map(
                        current: currentResult,
                        forecast: forecastResult
                    )

                    self.onStateChanged?(.loaded(uiModel))

                } catch {
                    let message = (error as? NetworkError)?.errorDescription
                        ?? error.localizedDescription
                    self.onStateChanged?(.error(message))
                }
            }
        }

        locationManager.onError = { [weak self] error in
            let message = error.localizedDescription ?? "Ошибка геолокации"
            self?.onStateChanged?(.error(message))
        }
    }
}
