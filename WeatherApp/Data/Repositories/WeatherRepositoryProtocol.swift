import Foundation

protocol WeatherRepositoryProtocol {
    func fetchWeather(lat: Double, lon: Double) async throws -> OneCallResponse
}
