import Foundation
import UIKit

// MARK: - DIContainer

final class DIContainer {
    
    // MARK: - Core Services (создаём один раз — синглтоны внутри контейнера)
    
    private lazy var networkService: NetworkServiceProtocol = {
        NetworkService()
    }()
    
    private lazy var locationManager: LocationManagerProtocol = {
        LocationManager()
    }()

    private lazy var locationNameResolver: LocationNameResolving = {
        ReverseGeocodingService()
    }()

    private lazy var currentLocationProvider: CurrentLocationProviderProtocol = {
        CurrentLocationProvider()
    }()

    private lazy var citySearchClient: CitySearchClientProtocol = {
        MapKitCitySearchClient()
    }()
    
    // MARK: - Repositories
    
    private lazy var weatherRepository: WeatherRepositoryProtocol = {
        WeatherRepository(networkService: networkService)
    }()

    private lazy var savedCitiesStore: SavedCitiesStoreProtocol = {
        UserDefaultsSavedCitiesStore()
    }()
    
    // MARK: - UseCases
    
    private lazy var getWeatherUseCase: GetWeatherUseCaseProtocol = {
        GetWeatherUseCase(repository: weatherRepository)
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
            getWeatherUseCase: getWeatherUseCase,
            currentLocationProvider: currentLocationProvider,
            locationNameResolver: locationNameResolver,
            citySearchClient: citySearchClient
        )
    }

    
    // MARK: - ViewControllers (публичный интерфейс)
    
    func makeWeatherPagerViewController() -> WeatherPagerViewController {
        WeatherPagerViewController(
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
