import Foundation

struct WeatherFormattingService {
    private let locale: Locale

    init(locale: Locale = .current) {
        self.locale = locale
    }

    var nowLabel: String { "Сейчас" }
    var todayLabel: String { "Сегодня" }
    var sunsetLabel: String { "Закат" }

    func temperature(_ celsius: Double) -> String {
        let measurement = Measurement(value: celsius, unit: UnitTemperature.celsius)
        return makeMeasurementFormatter().string(from: measurement)
    }

    func windSpeed(metersPerSecond: Double) -> String {
        let measurement = Measurement(value: metersPerSecond * 3.6, unit: UnitSpeed.kilometersPerHour)
        return makeMeasurementFormatter().string(from: measurement)
    }

    func percent(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: Double(value) / 100)) ?? "\(value)%"
    }

    func integer(_ value: Double) -> String {
        integer(Int(value.rounded()))
    }

    func integer(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    func pressure(_ hectopascals: Int) -> String {
        integer(hectopascals)
    }

    func time(timestamp: TimeInterval, timezoneIdentifier: String? = nil, timezoneOffset: Int) -> String {
        let formatter = makeDateFormatter(
            timezoneIdentifier: timezoneIdentifier,
            timezoneOffset: timezoneOffset
        )
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    func hourlyTime(timestamp: TimeInterval, timezoneIdentifier: String? = nil, timezoneOffset: Int) -> String {
        let formatter = makeDateFormatter(
            timezoneIdentifier: timezoneIdentifier,
            timezoneOffset: timezoneOffset
        )
        formatter.setLocalizedDateFormatFromTemplate("j")
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    func dayName(timestamp: TimeInterval, timezoneIdentifier: String? = nil, timezoneOffset: Int) -> String {
        let formatter = makeDateFormatter(
            timezoneIdentifier: timezoneIdentifier,
            timezoneOffset: timezoneOffset
        )
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: Date(timeIntervalSince1970: timestamp)).capitalized(with: locale)
    }

    func localTime(timezoneIdentifier: String? = nil, timezoneOffset: Int, date: Date = Date()) -> String {
        let formatter = makeDateFormatter(
            timezoneIdentifier: timezoneIdentifier,
            timezoneOffset: timezoneOffset
        )
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func highLowText(highCelsius: Double, lowCelsius: Double) -> String {
        "Макс. \(temperature(highCelsius))  Мин. \(temperature(lowCelsius))"
    }

    func maxMinText(maxCelsius: Double, minCelsius: Double) -> String {
        "Макс.: \(temperature(maxCelsius)), мин.: \(temperature(minCelsius))"
    }

    func windDirection(degrees: Int) -> String {
        let russianDirections = ["С", "СВ", "В", "ЮВ", "Ю", "ЮЗ", "З", "СЗ"]
        let englishDirections = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let directions = locale.identifier.lowercased().hasPrefix("ru") ? russianDirections : englishDirections
        let index = Int((Double(degrees) / 45.0).rounded()) % directions.count
        return "\(degrees)° \(directions[index])"
    }

    private func makeMeasurementFormatter() -> MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .short

        let numberFormatter = NumberFormatter()
        numberFormatter.locale = locale
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        numberFormatter.minimumFractionDigits = 0
        formatter.numberFormatter = numberFormatter

        return formatter
    }

    private func makeDateFormatter(timezoneIdentifier: String?, timezoneOffset: Int) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timezoneIdentifier
            .flatMap(TimeZone.init(identifier:))
            ?? TimeZone(secondsFromGMT: timezoneOffset)
            ?? .current
        return formatter
    }
}

final class WeatherMapper {

    static func map(
        response: OneCallResponse,
        locationName: String = "Текущее местоположение",
        isStale: Bool = false
    ) -> MainWeatherUIModel {
        let formatter = WeatherFormattingService()
        let current = response.current
        let hourly = mapHourly(
            hourly: response.hourly,
            timezoneIdentifier: response.timezone,
            timezoneOffset: response.timezoneOffset,
            currentSunset: current.sunset,
            formatter: formatter
        )
        let daily = mapDaily(
            daily: response.daily,
            timezoneIdentifier: response.timezone,
            timezoneOffset: response.timezoneOffset,
            formatter: formatter
        )
        let timeOfDay = TimeOfDay.fromTimezone(offset: response.timezoneOffset)
        let isRaining = isCurrentlyRaining(current: current)
        let feelsLike = current.feelsLike ?? current.temp
        let todayHigh = response.daily.first?.temp.max ?? current.temp
        let todayLow = response.daily.first?.temp.min ?? current.temp

        return MainWeatherUIModel(
            cityName: locationName,
            temperature: formatter.temperature(current.temp),
            description: sentenceCapitalized(current.weather?.first?.description ?? "Нет данных"),
            minMaxTemp: formatter.maxMinText(maxCelsius: todayHigh, minCelsius: todayLow),
            feelsLike: formatter.temperature(feelsLike),
            feelsLikeDetail: makeFeelsLikeDetail(actual: current.temp, feelsLike: feelsLike),
            humidity: formatter.percent(current.humidity ?? 0),
            windSpeed: formatter.windSpeed(metersPerSecond: current.windSpeed ?? 0),
            windGust: current.windGust.map { formatter.windSpeed(metersPerSecond: $0) } ?? "-",
            windDirection: formatter.windDirection(degrees: current.windDeg ?? 0),
            pressure: current.pressure.map(formatter.pressure) ?? "-",
            uvIndex: formatter.integer(current.uvi ?? 0),
            uvDescription: getUvDescription(current.uvi ?? 0),
            sunrise: current.sunrise.map {
                formatter.time(
                    timestamp: $0,
                    timezoneIdentifier: response.timezone,
                    timezoneOffset: response.timezoneOffset
                )
            } ?? "-",
            sunset: current.sunset.map {
                formatter.time(
                    timestamp: $0,
                    timezoneIdentifier: response.timezone,
                    timezoneOffset: response.timezoneOffset
                )
            } ?? "-",
            dewPoint: formatter.temperature(current.dewPoint ?? 0),
            todayMaxTemperature: formatter.temperature(todayHigh),
            hourlyForecast: hourly,
            dailyForecast: daily,
            conditionSummary: buildSummary(current: current, formatter: formatter),
            timeOfDay: timeOfDay,
            isRaining: isRaining,
            isStale: isStale
        )
    }

    // MARK: - Hourly

    private static func mapHourly(
        hourly: [HourlyWeather],
        timezoneIdentifier: String,
        timezoneOffset: Int,
        currentSunset: TimeInterval?,
        formatter: WeatherFormattingService
    ) -> [HourlyForecastUIModel] {
        var result: [HourlyForecastUIModel] = []

        let nextItems = hourly.prefix(24) // 24 часа
        let sunset = currentSunset ?? 0
        var sunsetInserted = false

        for (index, item) in nextItems.enumerated() {
            if index == 0 {
                result.append(HourlyForecastUIModel(
                    time: formatter.nowLabel,
                    temperature: formatter.temperature(item.temp),
                    symbolName: sfSymbol(for: item.weather?.first?.icon ?? "01d"),
                    isSpecial: false
                ))
                continue
            }

            if !sunsetInserted && sunset > 0 && item.dt > sunset {
                result.append(HourlyForecastUIModel(
                    time: formatter.time(
                        timestamp: sunset,
                        timezoneIdentifier: timezoneIdentifier,
                        timezoneOffset: timezoneOffset
                    ),
                    temperature: formatter.sunsetLabel,
                    symbolName: "sunset.fill",
                    isSpecial: true
                ))
                sunsetInserted = true
            }

            result.append(HourlyForecastUIModel(
                time: formatter.hourlyTime(
                    timestamp: item.dt,
                    timezoneIdentifier: timezoneIdentifier,
                    timezoneOffset: timezoneOffset
                ),
                temperature: formatter.temperature(item.temp),
                symbolName: sfSymbol(for: item.weather?.first?.icon ?? "01d"),
                isSpecial: false
            ))
        }

        return result
    }

    // MARK: - Daily

    private static func mapDaily(
        daily: [DailyWeather],
        timezoneIdentifier: String,
        timezoneOffset: Int,
        formatter: WeatherFormattingService
    ) -> [DailyForecastUIModel] {
        guard !daily.isEmpty else { return [] }

        return daily.enumerated().map { index, day in
            DailyForecastUIModel(
                dayName: index == 0 ? formatter.todayLabel : formatter.dayName(
                    timestamp: day.dt,
                    timezoneIdentifier: timezoneIdentifier,
                    timezoneOffset: timezoneOffset
                ),
                symbolName: sfSymbol(for: day.weather?.first?.icon ?? "01d"),
                conditionDescription: sentenceCapitalized(day.weather?.first?.description ?? "нет данных"),
                minTemp: Int(day.temp.min),
                maxTemp: Int(day.temp.max),
                minTemperatureText: formatter.temperature(day.temp.min),
                maxTemperatureText: formatter.temperature(day.temp.max),
                minTemperatureValue: day.temp.min,
                maxTemperatureValue: day.temp.max
            )
        }
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

    private static func buildSummary(current: CurrentWeather, formatter: WeatherFormattingService) -> String {
        let desc = current.weather?.first?.description ?? "переменная облачность"
        let gust = current.windGust.map { "Порывы ветра до \(formatter.windSpeed(metersPerSecond: $0)). " } ?? ""
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
