import Foundation

final class WeatherMapper {

    static func map(
        current: WeatherResponse,
        forecast: ForecastResponse
    ) -> MainWeatherUIModel {
        let hourly = mapHourly(current: current, forecast: forecast)
        let daily = mapDaily(forecast: forecast)
        let timeOfDay = TimeOfDay.current()
        let isRaining = isCurrentlyRaining(current: current)

        return MainWeatherUIModel(
            cityName: current.name,
            temperature: "\(Int(current.main.temp))°",
            description: (current.weather.first?.description ?? "").capitalized,
            minMaxTemp: "Макс.: \(Int(current.main.tempMax))°, мин.: \(Int(current.main.tempMin))°",
            feelsLike: "\(Int(current.main.feelsLike))°",
            humidity: "\(current.main.humidity) %",
            windSpeed: "\(Int(current.wind.speed * 3.6)) км/ч",
            windGust: "14 км/ч", // Gust нет в бесплатном API
            windDirection: formatWindDirection(degrees: current.wind.deg),
            pressure: "\(Int(Double(current.main.pressure) * 0.750064))",
            uvIndex: "0",           // UV нет в бесплатном API
            uvDescription: "Низкий",
            sunrise: formatTime(current.sys.sunrise),
            sunset: formatTime(current.sys.sunset),
            hourlyForecast: hourly,
            dailyForecast: daily,
            conditionSummary: buildSummary(current: current),
            timeOfDay: timeOfDay,
            isRaining: isRaining
        )
    }

    // MARK: - Hourly

    private static func mapHourly(
        current: WeatherResponse,
        forecast: ForecastResponse
    ) -> [HourlyForecastUIModel] {
        var result: [HourlyForecastUIModel] = []

        // Первый элемент — "Сейчас"
        result.append(HourlyForecastUIModel(
            time: "Сейчас",
            temperature: "\(Int(current.main.temp))°",
            symbolName: sfSymbol(for: current.weather.first?.icon ?? "01d"),
            isSpecial: false
        ))

        let nextItems = forecast.list.prefix(8) // 8 * 3ч = 24ч
        let sunset = current.sys.sunset
        var sunsetInserted = false

        for item in nextItems {
            // Вставляем закат перед слотом, который идёт после него
            if !sunsetInserted && sunset > 0 && item.dt > sunset {
                result.append(HourlyForecastUIModel(
                    time: formatTime(sunset),
                    temperature: "Закат",
                    symbolName: "sunset.fill",
                    isSpecial: true
                ))
                sunsetInserted = true
            }

            result.append(HourlyForecastUIModel(
                time: formatHour(item.dt),
                temperature: "\(Int(item.main.temp))°",
                symbolName: sfSymbol(for: item.weather.first?.icon ?? "01d"),
                isSpecial: false
            ))
        }

        return result
    }

    // MARK: - Daily

    private static func mapDaily(forecast: ForecastResponse) -> [DailyForecastUIModel] {
        // Группируем по дням
        var dayGroups: [String: [ForecastItem]] = [:]
        var dayOrder: [String] = []

        for item in forecast.list {
            let date = Date(timeIntervalSince1970: item.dt)
            let dayKey = dayKeyFormatter.string(from: date)

            if dayGroups[dayKey] == nil {
                dayOrder.append(dayKey)
            }
            dayGroups[dayKey, default: []].append(item)
        }

        // Для каждого дня — мин/макс температура
        var dailyData: [(day: String, min: Int, max: Int, icon: String)] = []

        for dayKey in dayOrder.prefix(10) {
            let items = dayGroups[dayKey] ?? []
            let temps = items.map { $0.main.temp }
            let minTemp = Int(temps.min() ?? 0)
            let maxTemp = Int(temps.max() ?? 0)
            let icon = items.first?.weather.first?.icon ?? "01d"
            dailyData.append((dayKey, minTemp, maxTemp, icon))
        }

        // Глобальный диапазон по всем дням
        let globalMin = dailyData.map { $0.min }.min() ?? 0
        let globalMax = dailyData.map { $0.max }.max() ?? 0

        return dailyData.enumerated().map { index, day in
            DailyForecastUIModel(
                dayName: index == 0 ? "Сегодня" : formatDayName(day.day),
                symbolName: sfSymbol(for: day.icon),
                minTemp: day.min,
                maxTemp: day.max,
                globalMin: globalMin,
                globalMax: globalMax
            )
        }
    }

    // MARK: - Formatters

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func formatTime(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private static func formatHour(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let f = DateFormatter()
        f.dateFormat = "HH"
        return f.string(from: date)
    }

    private static func formatDayName(_ dayKey: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: dayKey) else { return dayKey }
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "EE"
        return df.string(from: date).capitalized
    }

    private static func formatWindDirection(degrees: Int) -> String {
        let directions = ["С", "СВ", "В", "ЮВ", "Ю", "ЮЗ", "З", "СЗ"]
        let index = Int((Double(degrees) / 45.0).rounded()) % 8
        return "\(degrees)° \(directions[index])"
    }

    private static func buildSummary(current: WeatherResponse) -> String {
        let desc = current.weather.first?.description ?? "переменная облачность"
        let sunset = formatTime(current.sys.sunset)
        return "\(desc.capitalized) до конца дня. Закат в \(sunset)."
    }

    private static func isCurrentlyRaining(current: WeatherResponse) -> Bool {
        let weatherId = current.weather.first?.id ?? 800
        return weatherId < 700 // Коды < 700 — осадки (дождь, снег, гроза)
    }

    // MARK: - SF Symbols по коду иконки OpenWeatherMap

    static func sfSymbol(for icon: String) -> String {
        switch icon {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.stars.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.rain.fill"
        case "13d", "13n": return "snowflake"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }
}
