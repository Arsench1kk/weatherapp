import Foundation

final class WeatherMapper {

    static func map(response: OneCallResponse, locationName: String = "Текущее местоположение") -> MainWeatherUIModel {
        let current = response.current
        let hourly = mapHourly(hourly: response.hourly, timezoneOffset: response.timezoneOffset, currentSunset: current.sunset)
        let daily = mapDaily(daily: response.daily, timezoneOffset: response.timezoneOffset)
        let timeOfDay = TimeOfDay.fromTimezone(offset: response.timezoneOffset)
        let isRaining = isCurrentlyRaining(current: current)
        let feelsLike = current.feelsLike ?? current.temp

        return MainWeatherUIModel(
            cityName: locationName,
            temperature: "\(Int(current.temp))°",
            description: sentenceCapitalized(current.weather?.first?.description ?? "Нет данных"),
            minMaxTemp: "Макс.: \(daily.first?.maxTemp ?? Int(current.temp))°, мин.: \(daily.first?.minTemp ?? Int(current.temp))°",
            feelsLike: "\(Int(feelsLike))°",
            feelsLikeDetail: makeFeelsLikeDetail(actual: current.temp, feelsLike: feelsLike),
            humidity: "\(current.humidity ?? 0) %",
            windSpeed: "\(Int((current.windSpeed ?? 0) * 3.6)) км/ч",
            windGust: current.windGust.map { "\(Int($0 * 3.6)) км/ч" } ?? "-",
            windDirection: formatWindDirection(degrees: current.windDeg ?? 0),
            pressure: current.pressure.map(formatPressure) ?? "-",
            uvIndex: "\(Int(current.uvi ?? 0))",
            uvDescription: getUvDescription(current.uvi ?? 0),
            sunrise: formatTime(current.sunrise ?? 0, offset: response.timezoneOffset),
            sunset: formatTime(current.sunset ?? 0, offset: response.timezoneOffset),
            dewPoint: "\(Int(current.dewPoint ?? 0))°",
            todayMaxTemperature: "\(daily.first?.maxTemp ?? Int(current.temp))°",
            hourlyForecast: hourly,
            dailyForecast: daily,
            conditionSummary: buildSummary(current: current),
            timeOfDay: timeOfDay,
            isRaining: isRaining
        )
    }

    // MARK: - Hourly

    private static func mapHourly(
        hourly: [HourlyWeather],
        timezoneOffset: Int,
        currentSunset: TimeInterval?
    ) -> [HourlyForecastUIModel] {
        var result: [HourlyForecastUIModel] = []

        let nextItems = hourly.prefix(24) // 24 часа
        let sunset = currentSunset ?? 0
        var sunsetInserted = false

        for (index, item) in nextItems.enumerated() {
            if index == 0 {
                result.append(HourlyForecastUIModel(
                    time: "Сейчас",
                    temperature: "\(Int(item.temp))°",
                    symbolName: sfSymbol(for: item.weather?.first?.icon ?? "01d"),
                    isSpecial: false
                ))
                continue
            }

            if !sunsetInserted && sunset > 0 && item.dt > sunset {
                result.append(HourlyForecastUIModel(
                    time: formatTime(sunset, offset: timezoneOffset),
                    temperature: "Закат",
                    symbolName: "sunset.fill",
                    isSpecial: true
                ))
                sunsetInserted = true
            }

            result.append(HourlyForecastUIModel(
                time: formatHour(item.dt, offset: timezoneOffset),
                temperature: "\(Int(item.temp))°",
                symbolName: sfSymbol(for: item.weather?.first?.icon ?? "01d"),
                isSpecial: false
            ))
        }

        return result
    }

    // MARK: - Daily

    private static func mapDaily(daily: [DailyWeather], timezoneOffset: Int) -> [DailyForecastUIModel] {
        guard !daily.isEmpty else { return [] }

        return daily.enumerated().map { index, day in
            DailyForecastUIModel(
                dayName: index == 0 ? "Сегодня" : formatDayName(day.dt, offset: timezoneOffset),
                symbolName: sfSymbol(for: day.weather?.first?.icon ?? "01d"),
                conditionDescription: sentenceCapitalized(day.weather?.first?.description ?? "нет данных"),
                minTemp: Int(day.temp.min),
                maxTemp: Int(day.temp.max),
                minTemperatureValue: day.temp.min,
                maxTemperatureValue: day.temp.max
            )
        }
    }

    // MARK: - Formatters

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        return formatter
    }()

    private static let dayNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EE"
        return formatter
    }()

    private static let pressureFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()

    private static func formatTime(_ timestamp: TimeInterval, offset: Int) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        timeFormatter.timeZone = TimeZone(secondsFromGMT: offset) ?? .current
        return timeFormatter.string(from: date)
    }

    private static func formatHour(_ timestamp: TimeInterval, offset: Int) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        hourFormatter.timeZone = TimeZone(secondsFromGMT: offset) ?? .current
        return hourFormatter.string(from: date)
    }

    private static func formatDayName(_ timestamp: TimeInterval, offset: Int) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        dayNameFormatter.timeZone = TimeZone(secondsFromGMT: offset) ?? .current
        return dayNameFormatter.string(from: date).capitalized
    }

    private static func formatWindDirection(degrees: Int) -> String {
        let directions = ["С", "СВ", "В", "ЮВ", "Ю", "ЮЗ", "З", "СЗ"]
        let index = Int((Double(degrees) / 45.0).rounded()) % 8
        return "\(degrees)° \(directions[index])"
    }

    private static func formatPressure(_ pressureHPa: Int) -> String {
        pressureFormatter.string(from: NSNumber(value: pressureHPa)) ?? "\(pressureHPa)"
    }

    private static func getUvDescription(_ uvi: Double) -> String {
        switch uvi {
        case 0..<3: return "Низкий"
        case 3..<6: return "Умеренный"
        case 6..<8: return "Высокий"
        case 8..<11: return "Очень высокий"
        default: return "Экстремальный"
        }
    }

    private static func buildSummary(current: CurrentWeather) -> String {
        let desc = current.weather?.first?.description ?? "переменная облачность"
        let gust = current.windGust.map { "Порывы ветра до \(Int($0 * 3.6)) км/ч. " } ?? ""
        return "\(gust)\(sentenceCapitalized(desc)) до конца дня."
    }

    private static func sentenceCapitalized(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst().lowercased()
    }

    private static func isCurrentlyRaining(current: CurrentWeather) -> Bool {
        guard let weatherId = current.weather?.first?.id else { return false }
        return (200..<600).contains(weatherId)
    }

    private static func makeFeelsLikeDetail(actual: Double, feelsLike: Double) -> String {
        if feelsLike > actual {
            return "По ощущениям теплее, чем на самом деле."
        } else if feelsLike < actual {
            return "По ощущениям холоднее, чем на самом деле."
        } else {
            return "По ощущениям как фактическая температура."
        }
    }

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
