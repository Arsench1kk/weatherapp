import Foundation

struct WeatherResponse: Decodable {
    let name: String           // Название города
    let main: MainInfo
    let weather: [WeatherInfo]
    let wind: WindInfo
    let coord: Coordinates
}

struct MainInfo: Decodable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let humidity: Int
    let pressure: Int
}

struct WeatherInfo: Decodable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct WindInfo: Decodable {
    let speed: Double
    let deg: Int
}

struct Coordinates: Decodable {
    let lat: Double
    let lon: Double
}
