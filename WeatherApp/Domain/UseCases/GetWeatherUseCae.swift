import Foundation

protocol GetWeatherUseCaseProtocol {
    func execute(lat: Double, lon: Double) async throws -> WeatherResponse
}

final class GetWeatherUseCase: GetWeatherUseCaseProtocol {

    private let repository: WeatherRepositoryProtocol

    init(repository: WeatherRepositoryProtocol) {
        self.repository = repository
    }

    func execute(lat: Double, lon: Double) async throws -> WeatherResponse {
        try await repository.fetchCurrentWeather(lat: lat, lon: lon)
    }
}
