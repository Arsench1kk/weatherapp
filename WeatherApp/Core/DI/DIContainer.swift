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
    
    private func makeWeatherRepository() -> WeatherRepositoryProtocol {
        WeatherRepository(networkService: networkService)
    }
    
    // MARK: - UseCases
    
    private func makeGetWeatherUseCase() -> GetWeatherUseCaseProtocol {
        GetWeatherUseCase(repository: makeWeatherRepository())
    }
    
    // MARK: - ViewModels
    
    private func makeMainViewModel() -> MainViewModel {
        MainViewModel(
            getWeatherUseCase: makeGetWeatherUseCase(),
            locationManager: locationManager
        )
    }
    
    // MARK: - ViewControllers (публичный интерфейс)
    
    func makeMainViewController() -> MainViewController {
        MainViewController(viewModel: makeMainViewModel())
    }
}
