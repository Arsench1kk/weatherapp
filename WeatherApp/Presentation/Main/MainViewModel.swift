import Foundation
import CoreLocation

final class MainViewModel {

    private enum FetchPresentationMode {
        case initial
        case refresh

        var preservesContentOnError: Bool {
            self == .refresh
        }
    }

    // MARK: - Callback для ViewController

    var onStateChanged: ((MainScreenState) -> Void)?

    // MARK: - Dependencies

    private let getWeatherUseCase: GetWeatherUseCaseProtocol
    private var locationManager: LocationManagerProtocol
    private let locationNameResolver: LocationNameResolving
    private let source: WeatherLocationSource
    private var weatherTask: Task<Void, Never>?
    private var pendingPresentationMode: FetchPresentationMode = .initial
    private let fallbackLocationName = "Текущее местоположение"

    // MARK: - Init

    init(
        getWeatherUseCase: GetWeatherUseCaseProtocol,
        locationManager: LocationManagerProtocol,
        locationNameResolver: LocationNameResolving,
        source: WeatherLocationSource = .currentLocation
    ) {
        self.getWeatherUseCase = getWeatherUseCase
        self.locationManager = locationManager
        self.locationNameResolver = locationNameResolver
        self.source = source

        if case .currentLocation = source {
            setupLocationCallbacks()
        }
    }

    deinit {
        weatherTask?.cancel()
    }

    // MARK: - Public Interface

    func viewDidLoad() {
        fetchWeather(presentationMode: .initial)
    }

    func refresh() {
        fetchWeather(presentationMode: .refresh)
    }

    // MARK: - Private

    private func fetchWeather(presentationMode: FetchPresentationMode) {
        weatherTask?.cancel()
        pendingPresentationMode = presentationMode

        if presentationMode == .initial {
            onStateChanged?(.loading)
        }

        switch source {
        case .currentLocation:
            locationManager.requestPermission()

        case .fixedCity(let city):
            loadWeather(
                lat: city.latitude,
                lon: city.longitude,
                locationName: city.name,
                presentationMode: presentationMode
            )
        }
    }

    private func setupLocationCallbacks() {
        locationManager.onLocationUpdate = { [weak self] location in
            Task { @MainActor in
                guard let self else { return }
                self.loadWeather(for: location, presentationMode: self.pendingPresentationMode)
            }
        }

        locationManager.onError = { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                let message = error.errorDescription ?? "Ошибка геолокации"
                self.onStateChanged?(.error(
                    message,
                    preservesContent: self.pendingPresentationMode.preservesContentOnError
                ))
            }
        }
    }

    private func loadWeather(for location: CLLocation, presentationMode: FetchPresentationMode) {
        weatherTask?.cancel()

        weatherTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                async let resolvedLocationName = self.locationNameResolver.resolveName(for: location)
                let result = try await self.getWeatherUseCase.executeWithCacheResult(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude
                )
                guard !Task.isCancelled else { return }

                let locationName = await resolvedLocationName ?? self.fallbackLocationName
                self.applyWeatherResult(
                    result,
                    locationName: locationName
                )
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                let message = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
                self.onStateChanged?(.error(
                    message,
                    preservesContent: presentationMode.preservesContentOnError
                ))
            }
        }
    }

    private func loadWeather(
        lat: Double,
        lon: Double,
        locationName: String,
        presentationMode: FetchPresentationMode
    ) {
        weatherTask?.cancel()

        weatherTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let result = try await self.getWeatherUseCase.executeWithCacheResult(lat: lat, lon: lon)
                guard !Task.isCancelled else { return }
                self.applyWeatherResult(
                    result,
                    locationName: locationName
                )
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                let message = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
                self.onStateChanged?(.error(
                    message,
                    preservesContent: presentationMode.preservesContentOnError
                ))
            }
        }
    }

    private func applyWeatherResult(
        _ result: WeatherResponseResult,
        locationName: String
    ) {
        let uiModel = WeatherMapper.map(
            response: result.response,
            locationName: locationName,
            isStale: result.isStale
        )
        onStateChanged?(.loaded(uiModel))
    }
}
