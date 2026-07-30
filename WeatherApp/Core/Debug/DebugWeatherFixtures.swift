#if DEBUG
import Foundation

enum DebugWeatherTheme: String {
    case morning
    case day
    case evening
    case night
    case rainNight
}

enum DebugWeatherFixtures {

    static let defaultLocationName = "Отладочная локация"

    static let almaty = SavedCity(
        id: "debug-city-almaty",
        name: "Алматы",
        subtitle: "Казахстан",
        latitude: 43.2389,
        longitude: 76.8897
    )

    static let astana = SavedCity(
        id: "debug-city-astana",
        name: "Астана",
        subtitle: "Казахстан",
        latitude: 51.1694,
        longitude: 71.4491
    )

    static let tokyo = SavedCity(
        id: "debug-city-tokyo",
        name: "Токио",
        subtitle: "Япония",
        latitude: 35.6762,
        longitude: 139.6503
    )

    static var prefilledCities: [SavedCity] {
        [almaty, astana, tokyo]
    }

    static func response(
        theme: DebugWeatherTheme,
        lat: Double = almaty.latitude,
        lon: Double = almaty.longitude,
        date: Date = Date()
    ) -> OneCallResponse {
        let profile = WeatherProfile(theme: theme, date: date)
        let baseTimestamp = date.timeIntervalSince1970

        return OneCallResponse(
            lat: lat,
            lon: lon,
            timezone: "Debug/Scenario",
            timezoneOffset: profile.timezoneOffset,
            current: currentWeather(profile: profile, timestamp: baseTimestamp),
            hourly: hourlyWeather(profile: profile, baseTimestamp: baseTimestamp),
            daily: dailyWeather(profile: profile, baseTimestamp: baseTimestamp)
        )
    }

    private static func currentWeather(profile: WeatherProfile, timestamp: TimeInterval) -> CurrentWeather {
        CurrentWeather(
            dt: timestamp,
            sunrise: timestamp - 4 * 3_600,
            sunset: timestamp + 5 * 3_600,
            temp: profile.temperature,
            feelsLike: profile.temperature - 1,
            pressure: 1_017,
            humidity: profile.isRaining ? 88 : 48,
            dewPoint: profile.temperature - 4,
            uvi: profile.isRaining ? 1.0 : 4.5,
            clouds: profile.isRaining ? 96 : 18,
            visibility: profile.isRaining ? 7_000 : 10_000,
            windSpeed: profile.isRaining ? 6.4 : 3.2,
            windDeg: 42,
            windGust: profile.isRaining ? 10.5 : 5.8,
            weather: [profile.condition]
        )
    }

    private static func hourlyWeather(profile: WeatherProfile, baseTimestamp: TimeInterval) -> [HourlyWeather] {
        (0..<24).map { index in
            HourlyWeather(
                dt: baseTimestamp + TimeInterval(index * 3_600),
                temp: profile.temperature + Double(index % 5) - 2,
                feelsLike: profile.temperature + Double(index % 4) - 2,
                pressure: 1_017,
                humidity: profile.isRaining ? 85 : 50,
                dewPoint: profile.temperature - 4,
                uvi: profile.isRaining ? 1.0 : 4.0,
                clouds: profile.isRaining ? 94 : 22,
                visibility: profile.isRaining ? 7_000 : 10_000,
                windSpeed: profile.isRaining ? 6.0 : 3.0,
                windDeg: 42,
                windGust: profile.isRaining ? 10.0 : 5.0,
                weather: [profile.condition],
                pop: profile.isRaining ? 0.85 : 0.05
            )
        }
    }

    private static func dailyWeather(profile: WeatherProfile, baseTimestamp: TimeInterval) -> [DailyWeather] {
        (0..<10).map { index in
            let dayTimestamp = baseTimestamp + TimeInterval(index * 86_400)
            let high = profile.temperature + 4 + Double(index % 3)
            let low = profile.temperature - 4 - Double(index % 2)

            return DailyWeather(
                dt: dayTimestamp,
                sunrise: dayTimestamp - 4 * 3_600,
                sunset: dayTimestamp + 5 * 3_600,
                moonrise: nil,
                moonset: nil,
                moonPhase: nil,
                summary: profile.condition.description,
                temp: Temperature(
                    day: profile.temperature,
                    min: low,
                    max: high,
                    night: low + 1,
                    eve: profile.temperature - 1,
                    morn: low + 2
                ),
                feelsLike: FeelsLike(
                    day: profile.temperature - 1,
                    night: low,
                    eve: profile.temperature - 2,
                    morn: low + 1
                ),
                pressure: 1_017,
                humidity: profile.isRaining ? 88 : 48,
                dewPoint: profile.temperature - 4,
                windSpeed: profile.isRaining ? 6.4 : 3.2,
                windDeg: 42,
                windGust: profile.isRaining ? 10.5 : 5.8,
                weather: [profile.condition],
                clouds: profile.isRaining ? 96 : 18,
                pop: profile.isRaining ? 0.85 : 0.05,
                uvi: profile.isRaining ? 1.0 : 4.5
            )
        }
    }
}

private struct WeatherProfile {
    let theme: DebugWeatherTheme
    let timezoneOffset: Int
    let temperature: Double
    let condition: WeatherCondition

    var isRaining: Bool {
        (200..<600).contains(condition.id)
    }

    init(theme: DebugWeatherTheme, date: Date) {
        self.theme = theme

        switch theme {
        case .morning:
            timezoneOffset = Self.timezoneOffset(targetHour: 8, date: date)
            temperature = 12
            condition = WeatherCondition(id: 800, main: "Clear", description: "ясно", icon: "01d")
        case .day:
            timezoneOffset = Self.timezoneOffset(targetHour: 14, date: date)
            temperature = 22
            condition = WeatherCondition(id: 800, main: "Clear", description: "солнечно", icon: "01d")
        case .evening:
            timezoneOffset = Self.timezoneOffset(targetHour: 20, date: date)
            temperature = 17
            condition = WeatherCondition(id: 801, main: "Clouds", description: "малооблачно", icon: "02d")
        case .night:
            timezoneOffset = Self.timezoneOffset(targetHour: 2, date: date)
            temperature = 8
            condition = WeatherCondition(id: 800, main: "Clear", description: "ясная ночь", icon: "01n")
        case .rainNight:
            timezoneOffset = Self.timezoneOffset(targetHour: 2, date: date)
            temperature = 6
            condition = WeatherCondition(id: 500, main: "Rain", description: "небольшой дождь", icon: "10n")
        }
    }

    private static func timezoneOffset(targetHour: Int, date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        let utcHour = calendar.component(.hour, from: date)
        var deltaHours = targetHour - utcHour

        while deltaHours < -12 {
            deltaHours += 24
        }

        while deltaHours > 14 {
            deltaHours -= 24
        }

        return deltaHours * 3_600
    }
}
#endif
