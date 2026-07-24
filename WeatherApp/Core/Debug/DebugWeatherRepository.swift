#if DEBUG
import Foundation

final class DebugWeatherRepository: WeatherRepositoryProtocol {

    enum NetworkMode {
        case normal
        case slow
        case error
        case staleThenOffline
    }

    private let networkMode: NetworkMode
    private let theme: DebugWeatherTheme
    private var requestCount = 0

    init(
        networkMode: NetworkMode = .normal,
        theme: DebugWeatherTheme = .day
    ) {
        self.networkMode = networkMode
        self.theme = theme
    }

    func fetchWeather(lat: Double, lon: Double) async throws -> OneCallResponse {
        requestCount += 1

        switch networkMode {
        case .normal:
            break
        case .slow:
            try await Task.sleep(nanoseconds: 3_000_000_000)
        case .error:
            throw NetworkError.noInternetConnection
        case .staleThenOffline:
            if requestCount > 1 {
                throw NetworkError.noInternetConnection
            }
        }

        try Task.checkCancellation()
        return DebugWeatherFixtures.response(theme: theme, lat: lat, lon: lon)
    }
}
#endif
