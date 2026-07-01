import CoreLocation

protocol GetWeatherUseCaseProtocol {
    func execute(for location: CLLocation) async throws -> WeatherResponse
}

final class GetWeatherUseCase: GetWeatherUseCaseProtocol {
    
    private let repository: WeatherRepositoryProtocol
    
    init(repository: WeatherRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(for location: CLLocation) async throws -> WeatherResponse {
        try await repository.getWeather(for: location)
    }
}
