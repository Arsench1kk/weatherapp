import Foundation
import UIKit

// MARK: - DIContainer

final class DIContainer {

    #if DEBUG
    private let debugScenario: DebugScenarioConfig?

    init(debugScenario: DebugScenarioConfig? = DebugScenarioConfig.current) {
        self.debugScenario = debugScenario
    }
    #else
    init() {}
    #endif
    
    // MARK: - Core Services (создаём один раз — синглтоны внутри контейнера)
    
    private lazy var networkService: NetworkServiceProtocol = {
        NetworkService()
    }()
    
    private lazy var locationManager: LocationManagerProtocol = {
        #if DEBUG
        if let debugScenario {
            return DebugLocationManager(mode: debugLocationMode(for: debugScenario))
        }
        #endif

        return LocationManager()
    }()

    private lazy var locationNameResolver: LocationNameResolving = {
        #if DEBUG
        if debugScenario != nil {
            return DebugLocationNameResolver()
        }
        #endif

        return ReverseGeocodingService()
    }()

    private lazy var currentLocationProvider: CurrentLocationProviderProtocol = {
        #if DEBUG
        if let debugScenario {
            return DebugCurrentLocationProvider(mode: debugLocationMode(for: debugScenario))
        }
        #endif

        return CurrentLocationProvider()
    }()

    private lazy var citySearchClient: CitySearchClientProtocol = {
        #if DEBUG
        if let searchScenario = debugScenario?.search {
            return DebugCitySearchClient(scenario: searchScenario)
        }
        #endif

        return MapKitCitySearchClient()
    }()
    
    // MARK: - Repositories
    
    private lazy var weatherRepository: WeatherRepositoryProtocol = {
        #if DEBUG
        if let debugScenario {
            return DebugWeatherRepository(
                networkMode: debugNetworkMode(for: debugScenario),
                theme: debugScenario.theme ?? .day
            )
        }
        #endif

        return WeatherRepository(networkService: networkService)
    }()

    private lazy var savedCitiesStore: SavedCitiesStoreProtocol = {
        #if DEBUG
        if let debugScenario {
            return DebugSavedCitiesStore(cities: debugSavedCities(for: debugScenario))
        }
        #endif

        return UserDefaultsSavedCitiesStore()
    }()

    private lazy var weatherCache: WeatherCacheProtocol = {
        #if DEBUG
        if debugScenario != nil {
            return InMemoryWeatherCache()
        }
        #endif

        return UserDefaultsWeatherCache()
    }()
    
    // MARK: - UseCases
    
    private lazy var getWeatherUseCase: GetWeatherUseCaseProtocol = {
        GetWeatherUseCase(repository: weatherRepository, cache: weatherCache)
    }()

    private lazy var cityWeatherPreviewLoader: CityWeatherPreviewLoader = {
        CityWeatherPreviewLoader(
            getWeatherUseCase: getWeatherUseCase,
            currentLocationProvider: currentLocationProvider,
            locationNameResolver: locationNameResolver
        )
    }()
    
    // MARK: - ViewModels
    
    private func makeMainViewModel(source: WeatherLocationSource = .currentLocation) -> MainViewModel {
        MainViewModel(
            getWeatherUseCase: getWeatherUseCase,
            locationManager: locationManager,
            locationNameResolver: locationNameResolver,
            source: source
        )
    }

    private func makeCitySearchViewModel() -> CitySearchViewModel {
        CitySearchViewModel(
            savedCitiesStore: savedCitiesStore,
            citySearchClient: citySearchClient,
            previewLoader: cityWeatherPreviewLoader
        )
    }

    
    // MARK: - ViewControllers (публичный интерфейс)
    
    func makeWeatherPagerViewController() -> WeatherPagerViewController {
        let viewController = WeatherPagerViewController(
            savedCitiesStore: savedCitiesStore,
            makeMainViewController: { [unowned self] source in
                self.makeMainViewController(source: source)
            },
            makeCitySearchViewController: { [unowned self] backgroundTheme, onCitySelection in
                self.makeCitySearchViewController(
                    backgroundTheme: backgroundTheme,
                    onCitySelection: onCitySelection
                )
            }
        )

        #if DEBUG
        if let debugScenario,
           let debugScript = DebugPagerScript(scenario: debugScenario) {
            viewController.configureDebugScript(debugScript)
        }
        #endif

        return viewController
    }

    func makeMainViewController(source: WeatherLocationSource = .currentLocation) -> MainViewController {
        MainViewController(
            viewModel: makeMainViewModel(source: source),
            source: source
        )
    }

    func makeCitySearchViewController(
        backgroundTheme: WeatherTheme = .current,
        onCitySelection: @escaping (CitySelection) -> Void
    ) -> CitySearchViewController {
        let viewController = CitySearchViewController(
            viewModel: makeCitySearchViewModel(),
            backgroundTheme: backgroundTheme
        )
        viewController.onCitySelection = onCitySelection
        return viewController
    }

}

#if DEBUG
private extension DIContainer {

    func debugLocationMode(for scenario: DebugScenarioConfig) -> DebugLocationManager.Mode {
        switch scenario.location {
        case .denied:
            return .denied
        case .unavailable:
            return .unavailable
        case nil:
            return .available
        }
    }

    func debugNetworkMode(for scenario: DebugScenarioConfig) -> DebugWeatherRepository.NetworkMode {
        switch scenario.network {
        case .slow:
            return .slow
        case .error:
            return .error
        case .staleThenOffline:
            return .staleThenOffline
        case nil:
            return .normal
        }
    }

    func debugSavedCities(for scenario: DebugScenarioConfig) -> [SavedCity] {
        if scenario.search == .duplicate
            || scenario.initialCity != nil
            || scenario.deleteActiveCityAfter != nil {
            return DebugWeatherFixtures.prefilledCities
        }

        switch scenario.savedCities {
        case .prefilled:
            return DebugWeatherFixtures.prefilledCities
        case .empty, nil:
            return []
        }
    }
}
#endif
