import Foundation

// MARK: - Forecast API Response (DTO)

struct ForecastResponse: Decodable {
    let list: [ForecastItem]
    let city: ForecastCity
}

struct ForecastItem: Decodable {
    let dt: TimeInterval        // Unix timestamp
    let main: ForecastMain
    let weather: [WeatherCondition]
    let dtTxt: String           // "2024-01-15 12:00:00"

    enum CodingKeys: String, CodingKey {
        case dt, main, weather
        case dtTxt = "dt_txt"
    }
}

struct ForecastMain: Decodable {
    let temp: Double
    let tempMin: Double
    let tempMax: Double
    let feelsLike: Double
    let humidity: Int

    enum CodingKeys: String, CodingKey {
        case temp, humidity
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case feelsLike = "feels_like"
    }
}

struct WeatherCondition: Decodable {
    let id: Int
    let main: String        // "Clear", "Clouds", "Rain"
    let description: String // "ясно", "переменная облачность"
    let icon: String        // "01d", "04n"
}

struct ForecastCity: Decodable {
    let name: String
    let sunrise: TimeInterval
    let sunset: TimeInterval
}
