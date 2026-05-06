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
            locationNameResolver: locationNameResolver
        )
    }

    
    // MARK: - ViewControllers (публичный интерфейс)
    
    func makeMainViewController(source: WeatherLocationSource = .currentLocation) -> MainViewController {
        let viewController = MainViewController(viewModel: makeMainViewModel(source: source))
        if case .currentLocation = source {
            viewController.configureFavoritePager(isCurrentLocation: true)
        } else {
            viewController.configureFavoritePager(isCurrentLocation: false)
        }

        viewController.onFavoriteSwitchTapped = { [weak self, weak viewController] in
            guard let self,
                  let viewController,
                  let navigationController = viewController.navigationController,
                  let nextSource = self.nextFavoriteSource(after: source) else {
                return
            }

            switch nextSource {
            case .currentLocation:
                navigationController.popToRootViewController(animated: true)

            case .fixedCity:
                let nextViewController = self.makeMainViewController(source: nextSource)
                if case .currentLocation = source {
                    navigationController.pushViewController(nextViewController, animated: true)
                } else if navigationController.viewControllers.last === viewController {
                    var viewControllers = navigationController.viewControllers
                    viewControllers[viewControllers.count - 1] = nextViewController
                    navigationController.setViewControllers(viewControllers, animated: false)
                } else {
                    navigationController.pushViewController(nextViewController, animated: true)
                }
            }
        }

        viewController.onSearchTapped = { [weak self, weak viewController] in
            guard let self,
                  let viewController,
                  let navigationController = viewController.navigationController else {
                return
            }

            let backgroundTheme = viewController.currentWeatherTheme()
            let searchViewController = self.makeCitySearchViewController(backgroundTheme: backgroundTheme) { [weak self, weak navigationController] selection in
                guard let self,
                      let navigationController else {
                    return
                }

                switch selection {
                case .currentLocation:
                    navigationController.popToRootViewController(animated: true)

                case .savedCity(let city):
                    let cityWeatherViewController = self.makeMainViewController(source: .fixedCity(city))
                    navigationController.pushViewController(cityWeatherViewController, animated: true)
                }
            }

            navigationController.pushViewController(searchViewController, animated: true)
        }

        return viewController
    }

    private func nextFavoriteSource(after source: WeatherLocationSource) -> WeatherLocationSource? {
        let savedCities = savedCitiesStore.loadCities()
        guard !savedCities.isEmpty else { return nil }

        switch source {
        case .currentLocation:
            return .fixedCity(savedCities[0])

        case .fixedCity(let currentCity):
            guard let currentIndex = savedCities.firstIndex(where: { $0.id == currentCity.id }) else {
                return .currentLocation
            }

            let nextIndex = currentIndex + 1
            guard savedCities.indices.contains(nextIndex) else {
                return .currentLocation
            }

            return .fixedCity(savedCities[nextIndex])
        }
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
