import Foundation

struct WeatherResponse: Decodable {
    let name: String?
    let coord: Coord?
    let main: MainWeather
    let weather: [WeatherCondition]?
    let wind: Wind?
    let sys: Sys?
    let dt: TimeInterval?
}

struct Coord: Decodable {
    let lat: Double?
    let lon: Double?
}

struct MainWeather: Decodable {
    let temp: Double
    let feelsLike: Double?
    let tempMin: Double?
    let tempMax: Double?
    let humidity: Int?
    let pressure: Int?

    enum CodingKeys: String, CodingKey {
        case temp, humidity, pressure
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
    }
}

struct Wind: Decodable {
    let speed: Double?
    let deg: Int?
}

struct Sys: Decodable {
    let sunrise: TimeInterval?
    let sunset: TimeInterval?
}
