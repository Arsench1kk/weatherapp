import Foundation

// MARK: - DIContainer

final class DIContainer {
    
    // MARK: - Core Services (создаём один раз — синглтоны внутри контейнера)
    
    private lazy var networkService: NetworkServiceProtocol = {
        NetworkService()
    }()
    
    private lazy var locationManager: LocationManagerProtocol = {
        LocationManager()
    }()
    
    // MARK: - Repositories
    
    private lazy var weatherRepository: WeatherRepositoryProtocol = {
        WeatherRepository(networkService: networkService)
    }()
    
    // MARK: - UseCases
    
    private lazy var getWeatherUseCase: GetWeatherUseCaseProtocol = {
        GetWeatherUseCase(repository: weatherRepository)
    }()
    
    // MARK: - ViewModels
    
    private func makeMainViewModel() -> MainViewModel {
        MainViewModel(
            getWeatherUseCase: getWeatherUseCase,
            locationManager: locationManager
        )
    }

    
    // MARK: - ViewControllers (публичный интерфейс)
    
    func makeMainViewController() -> MainViewController {
        MainViewController(viewModel: makeMainViewModel())
    }

}
