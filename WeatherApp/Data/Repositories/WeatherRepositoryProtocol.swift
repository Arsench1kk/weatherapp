import Foundation

protocol WeatherRepositoryProtocol {
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> WeatherResponse
    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastResponse
}
