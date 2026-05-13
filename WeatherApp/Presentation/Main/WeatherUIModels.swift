import Foundation

// MARK: - Главная UI-модель экрана

struct MainWeatherUIModel {
    let cityName: String        // "Алматы"
    let temperature: String     // Locale-aware temperature
    let description: String     // "В основном солнечно"
    let minMaxTemp: String      // Locale-aware max/min summary
    let feelsLike: String       // Locale-aware temperature
    let feelsLikeDetail: String // "По ощущениям теплее..."
    let humidity: String        // "70 %"
    let windSpeed: String       // Locale-aware speed
    let windGust: String        // Locale-aware speed
    let windDirection: String   // "38° СВ"
    let pressure: String        // "1 022"
    let uvIndex: String         // "0"
    let uvDescription: String   // "Низкий"
    let sunrise: String         // "06:41"
    let sunset: String          // "17:29"
    let dewPoint: String        // Locale-aware temperature
    let todayMaxTemperature: String // Locale-aware temperature
    let hourlyForecast: [HourlyForecastUIModel]
    let dailyForecast: [DailyForecastUIModel]
    let conditionSummary: String // Текст для погодного тезиса
    let timeOfDay: TimeOfDay     // Для выбора фона
    let isRaining: Bool          // Для выбора фона
}

struct WeatherTheme: Equatable {
    let timeOfDay: TimeOfDay
    let isRaining: Bool

    static var current: WeatherTheme {
        WeatherTheme(timeOfDay: .current(), isRaining: false)
    }
}

// MARK: - Почасовой прогноз

struct HourlyForecastUIModel {
    let time: String        // "16", "17", "17:29" (для заката — "Закат")
    let temperature: String // Locale-aware temperature
    let symbolName: String  // SF Symbol: "sun.max.fill", "moon.stars.fill"
    let isSpecial: Bool     // true для заката/восхода
}

// MARK: - Дневной прогноз

struct DailyForecastUIModel {
    let dayName: String     // "Сегодня", "Сб", "Вс"
    let symbolName: String  // SF Symbol
    let conditionDescription: String
    let minTemp: Int        // -2
    let maxTemp: Int        // 9
    let minTemperatureText: String
    let maxTemperatureText: String
    let minTemperatureValue: Double
    let maxTemperatureValue: Double
}

// MARK: - Время суток (для градиента)

enum TimeOfDay: Equatable {
    case morning    // 6:00 - 12:00
    case day        // 12:00 - 18:00
    case evening    // 18:00 - 24:00
    case night      // 0:00 - 6:00

    static func current() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        return make(from: hour)
    }

    static func fromTimezone(offset: Int, date: Date = Date()) -> TimeOfDay {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        let localDate = Date(timeIntervalSince1970: date.timeIntervalSince1970 + TimeInterval(offset))
        let hour = calendar.component(.hour, from: localDate)
        return make(from: hour)
    }

    private static func make(from hour: Int) -> TimeOfDay {
        switch hour {
        case 6..<12: return .morning
        case 12..<18: return .day
        case 18..<24: return .evening
        default: return .night
        }
    }
}
