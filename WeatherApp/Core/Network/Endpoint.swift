import Foundation

struct Endpoint {
    let path: String
    var queryItems: [URLQueryItem] = []
    
    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.openweathermap.org"
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
}

// MARK: - Weather Endpoints

extension Endpoint {
    static func currentWeather(lat: Double, lon: Double) -> Endpoint {
        Endpoint(
            path: "/data/2.5/weather",
            queryItems: [
                URLQueryItem(name: "lat", value: "\(lat)"),
                URLQueryItem(name: "lon", value: "\(lon)"),
                URLQueryItem(name: "appid", value: Constants.apiKey),
                URLQueryItem(name: "units", value: "metric"),
                URLQueryItem(name: "lang", value: "ru")
            ]
        )
    }
    static func forecast(lat: Double, lon: Double) -> Endpoint {
        Endpoint(
            path: "/data/2.5/forecast",
            queryItems: [
                URLQueryItem(name: "lat", value: "\(lat)"),
                URLQueryItem(name: "lon", value: "\(lon)"),
                URLQueryItem(name: "appid", value: Constants.apiKey),
                URLQueryItem(name: "units", value: "metric"),
                URLQueryItem(name: "lang", value: "ru")
            ]
        )
    }
}

// MARK: - Constants

enum Constants {
    // ВАЖНО: в реальном проекте храни ключ в xcconfig или environment variable
    // Никогда не пушь API ключ в публичный репозиторий!
    static let apiKey = "2fbe05798a0852f0d7bc68e4fc0b9ac1"
}
