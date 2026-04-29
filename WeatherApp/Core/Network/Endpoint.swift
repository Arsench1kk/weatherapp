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
    static func oneCall(lat: Double, lon: Double) -> Endpoint {
        Endpoint(
            path: "/data/3.0/onecall",
            queryItems: [
                URLQueryItem(name: "lat", value: "\(lat)"),
                URLQueryItem(name: "lon", value: "\(lon)"),
                URLQueryItem(name: "exclude", value: "minutely,alerts"),
                URLQueryItem(name: "appid", value: Constants.apiKey),
                URLQueryItem(name: "units", value: "metric"),
                URLQueryItem(name: "lang", value: "ru")
            ]
        )
    }
}

// MARK: - Constants

enum Constants {
    static var apiKey: String {
        return "2fbe05798a0852f0d7bc68e4fc0b9ac1"
    }
}
