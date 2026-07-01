import CoreLocation

final class WeatherRepository: WeatherRepositoryProtocol {
    
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func getWeather(for location: CLLocation) async throws -> WeatherResponse {
        let endpoint = Endpoint.currentWeather(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude
        )
        return try await networkService.fetch(endpoint)
    }
}
