import Foundation

final class WeatherRepository: WeatherRepositoryProtocol {
    
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
        let endpoint = Endpoint.currentWeather(lat: lat, lon: lon)
        return try await networkService.fetch(endpoint)
    }
    
    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastResponse {
        let endpoint = Endpoint.forecast(lat: lat, lon: lon)
        return try await networkService.fetch(endpoint)
    }
}
