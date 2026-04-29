import Foundation

let apiKey = "2fbe05798a0852f0d7bc68e4fc0b9ac1"

let urlStr = "https://api.openweathermap.org/data/3.0/onecall?lat=33.44&lon=-94.04&exclude=minutely,alerts&units=metric&lang=ru&appid=\(apiKey)"
guard let url = URL(string: urlStr) else { exit(1) }

let sema = DispatchSemaphore(value: 0)

let task = URLSession.shared.dataTask(with: url) { data, response, error in
    defer { sema.signal() }
    guard let data = data else { 
        print("No data")
        return 
    }
    
    // print(String(data: data, encoding: .utf8) ?? "")
    
    struct OneCallResponse: Decodable {
        let lat: Double
        let lon: Double
        let timezone: String
        let timezoneOffset: Int
        let current: CurrentWeather
        let hourly: [HourlyWeather]
        let daily: [DailyWeather]

        enum CodingKeys: String, CodingKey {
            case lat, lon, timezone, current, hourly, daily
            case timezoneOffset = "timezone_offset"
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
            case feelsLike = "feels_like"
            case dewPoint = "dew_point"
            case windSpeed = "wind_speed"
            case windDeg = "wind_deg"
            case windGust = "wind_gust"
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
            case feelsLike = "feels_like"
            case dewPoint = "dew_point"
            case windSpeed = "wind_speed"
            case windDeg = "wind_deg"
            case windGust = "wind_gust"
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
            case moonPhase = "moon_phase"
            case feelsLike = "feels_like"
            case dewPoint = "dew_point"
            case windSpeed = "wind_speed"
            case windDeg = "wind_deg"
            case windGust = "wind_gust"
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
    
    do {
        _ = try JSONDecoder().decode(OneCallResponse.self, from: data)
        print("Success")
    } catch {
        print("Error: \(error)")
        print(String(data: data, encoding: .utf8) ?? "")
    }
}
task.resume()
sema.wait()
