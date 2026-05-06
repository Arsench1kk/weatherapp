import Foundation

struct OneCallResponse: Decodable {
    let lat: Double
    let lon: Double
    let timezone: String
    let timezoneOffset: Int
    let current: CurrentWeather
    let hourly: [HourlyWeather]
    let daily: [DailyWeather]

    enum CodingKeys: String, CodingKey {
        case lat, lon, timezone, current, hourly, daily, timezoneOffset
    }
}

struct CurrentWeather: Decodable {
    let dt: TimeInterval
    let sunrise: TimeInterval?
    let sunset: TimeInterval?
    let temp: Double
    let feelsLike: Double?
    let pressure: Int?
    let humidity: Int?
    let dewPoint: Double?
    let uvi: Double?
    let clouds: Int?
    let visibility: Int?
    let windSpeed: Double?
    let windDeg: Int?
    let windGust: Double?
    let weather: [WeatherCondition]?

    enum CodingKeys: String, CodingKey {
        case dt, sunrise, sunset, temp, pressure, humidity, uvi, clouds, visibility, weather
        case feelsLike, dewPoint, windSpeed, windDeg, windGust
    }
}

struct HourlyWeather: Decodable {
    let dt: TimeInterval
    let temp: Double
    let feelsLike: Double?
    let pressure: Int?
    let humidity: Int?
    let dewPoint: Double?
    let uvi: Double?
    let clouds: Int?
    let visibility: Int?
    let windSpeed: Double?
    let windDeg: Int?
    let windGust: Double?
    let weather: [WeatherCondition]?
    let pop: Double?

    enum CodingKeys: String, CodingKey {
        case dt, temp, pressure, humidity, uvi, clouds, visibility, weather, pop
        case feelsLike, dewPoint, windSpeed, windDeg, windGust
    }
}

struct DailyWeather: Decodable {
    let dt: TimeInterval
    let sunrise: TimeInterval?
    let sunset: TimeInterval?
    let moonrise: TimeInterval?
    let moonset: TimeInterval?
    let moonPhase: Double?
    let summary: String?
    let temp: Temperature
    let feelsLike: FeelsLike?
    let pressure: Int?
    let humidity: Int?
    let dewPoint: Double?
    let windSpeed: Double?
    let windDeg: Int?
    let windGust: Double?
    let weather: [WeatherCondition]?
    let clouds: Int?
    let pop: Double?
    let uvi: Double?

    enum CodingKeys: String, CodingKey {
        case dt, sunrise, sunset, moonrise, moonset, summary, temp, pressure, humidity, weather, clouds, pop, uvi
        case moonPhase, feelsLike, dewPoint, windSpeed, windDeg, windGust
    }
}

struct Temperature: Decodable {
    let day: Double
    let min: Double
    let max: Double
    let night: Double
    let eve: Double
    let morn: Double
}

struct FeelsLike: Decodable {
    let day: Double
    let night: Double
    let eve: Double
    let morn: Double
}

struct WeatherCondition: Decodable {
    let id: Int
    let main: String?
    let description: String?
    let icon: String?
}
