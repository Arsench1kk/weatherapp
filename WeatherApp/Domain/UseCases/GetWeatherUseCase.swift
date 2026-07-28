import Foundation

struct WeatherResponseResult {
    let response: OneCallResponse
    let isStale: Bool
}

protocol GetWeatherUseCaseProtocol {
    func execute(lat: Double, lon: Double) async throws -> OneCallResponse
    func executeWithCacheResult(lat: Double, lon: Double) async throws -> WeatherResponseResult
}

final class GetWeatherUseCase: GetWeatherUseCaseProtocol {

    private let repository: WeatherRepositoryProtocol
    private let cache: WeatherCacheProtocol

    init(repository: WeatherRepositoryProtocol, cache: WeatherCacheProtocol) {
        self.repository = repository
        self.cache = cache
    }

    func execute(lat: Double, lon: Double) async throws -> OneCallResponse {
        try await executeWithCacheResult(lat: lat, lon: lon).response
    }

    func executeWithCacheResult(lat: Double, lon: Double) async throws -> WeatherResponseResult {
        let cacheKey = makeCacheKey(lat: lat, lon: lon)

        do {
            let response = try await repository.fetchWeather(lat: lat, lon: lon)
            cache.save(response, for: cacheKey)
            return WeatherResponseResult(response: response, isStale: false)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if let cachedResponse = cache.cachedResponse(for: cacheKey) {
                return WeatherResponseResult(response: cachedResponse, isStale: true)
            }
            throw error
        }
    }

    private func makeCacheKey(lat: Double, lon: Double) -> String {
        let roundedLat = (lat * 100).rounded() / 100
        let roundedLon = (lon * 100).rounded() / 100
        return "\(roundedLat),\(roundedLon)"
    }
}
