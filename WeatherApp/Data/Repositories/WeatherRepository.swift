import Foundation

final class WeatherRepository: WeatherRepositoryProtocol {
    
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func fetchWeather(lat: Double, lon: Double) async throws -> OneCallResponse {
        let endpoint = Endpoint.oneCall(lat: lat, lon: lon)
        return try await networkService.fetch(endpoint)
    }
}
