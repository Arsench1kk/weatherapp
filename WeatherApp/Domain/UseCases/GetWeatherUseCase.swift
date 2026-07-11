import Foundation

protocol GetWeatherUseCaseProtocol {
    func execute(lat: Double, lon: Double) async throws -> OneCallResponse
}

final class GetWeatherUseCase: GetWeatherUseCaseProtocol {

    private let repository: WeatherRepositoryProtocol

    init(repository: WeatherRepositoryProtocol) {
        self.repository = repository
    }

    func execute(lat: Double, lon: Double) async throws -> OneCallResponse {
        try await repository.fetchWeather(lat: lat, lon: lon)
    }
}
