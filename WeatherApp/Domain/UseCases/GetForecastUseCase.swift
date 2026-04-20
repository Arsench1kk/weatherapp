import Foundation

protocol GetForecastUseCaseProtocol {
    func execute(lat: Double, lon: Double) async throws -> ForecastResponse
}

final class GetForecastUseCase: GetForecastUseCaseProtocol {

    private let repository: WeatherRepositoryProtocol

    init(repository: WeatherRepositoryProtocol) {
        self.repository = repository
    }

    func execute(lat: Double, lon: Double) async throws -> ForecastResponse {
        try await repository.fetchForecast(lat: lat, lon: lon)
    }
}
