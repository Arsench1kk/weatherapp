import CoreLocation

protocol WeatherRepositoryProtocol {
    func getWeather(for location: CLLocation) async throws -> WeatherResponse
}
