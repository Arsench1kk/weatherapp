import Foundation

// MARK: - Главная UI-модель экрана

struct MainWeatherUIModel {
    let cityName: String        // "Алматы"
    let temperature: String     // "11°"
    let description: String     // "В основном солнечно"
    let minMaxTemp: String      // "Макс.: 11°, мин.: 5°"
    let feelsLike: String       // "12°"
    let humidity: String        // "70 %"
    let windSpeed: String       // "6 км/ч"
    let windGust: String        // "14 км/ч"
    let windDirection: String   // "38° СВ"
    let pressure: String        // "1 022"
    let uvIndex: String         // "0"
    let uvDescription: String   // "Низкий"
    let sunrise: String         // "06:41"
    let sunset: String          // "17:29"
    let hourlyForecast: [HourlyForecastUIModel]
    let dailyForecast: [DailyForecastUIModel]
    let conditionSummary: String // Текст для погодного тезиса
    let timeOfDay: TimeOfDay     // Для выбора фона
    let isRaining: Bool          // Для выбора фона
}

// MARK: - Почасовой прогноз

struct HourlyForecastUIModel {
    let time: String        // "16", "17", "17:29" (для заката — "Закат")
    let temperature: String // "11°"
    let symbolName: String  // SF Symbol: "sun.max.fill", "moon.stars.fill"
    let isSpecial: Bool     // true для заката/восхода
}

// MARK: - Дневной прогноз (10 дней)

struct DailyForecastUIModel {
    let dayName: String     // "Сегодня", "Сб", "Вс"
    let symbolName: String  // SF Symbol
    let minTemp: Int        // -2
    let maxTemp: Int        // 9
    // Для температурной шкалы:
    let globalMin: Int      // Глобальный минимум по всем 10 дням
    let globalMax: Int      // Глобальный максимум по всем 10 дням
}

// MARK: - Время суток (для градиента)

enum TimeOfDay {
    case morning    // 6:00 - 12:00
    case day        // 12:00 - 18:00
    case evening    // 18:00 - 24:00
    case night      // 0:00 - 6:00

    static func current() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<18: return .day
        case 18..<24: return .evening
        default: return .night
        }
    }
}
