import UIKit

enum AppColors {

    // MARK: - Backgrounds

    static var backgroundPrimary: UIColor {
        asset("BackgroundPrimary")
    }

    static var backgroundSecondary: UIColor {
        asset("BackgroundSecondary")
    }

    // MARK: - Text

    static var textPrimary: UIColor {
        asset("WeatherTextPrimary")
    }

    static var textSecondary: UIColor {
        asset("WeatherTextSecondary")
    }

    // MARK: - Accent

    static var accentBlue: UIColor {
        asset("AccentBlue")
    }

    // MARK: - Weather specific

    static var weatherCardBackground: UIColor {
        asset("WeatherCardBackground")
    }

    static var weatherSeparator: UIColor {
        asset("WeatherSeparator")
    }

    static var weatherIconPrimary: UIColor {
        asset("WeatherIconPrimary")
    }

    static var weatherIconSecondary: UIColor {
        asset("WeatherIconSecondary")
    }

    static var weatherTemperatureBarTrack: UIColor {
        asset("WeatherTemperatureBarTrack")
    }

    static var weatherTemperatureBarStart: UIColor {
        asset("WeatherTemperatureBarStart")
    }

    static var weatherTemperatureBarEnd: UIColor {
        asset("WeatherTemperatureBarEnd")
    }

    static var weatherTemperatureMarker: UIColor {
        asset("WeatherTemperatureMarker")
    }

    static var weatherTemperatureMarkerBorder: UIColor {
        asset("WeatherTemperatureMarkerBorder")
    }

    static var weatherErrorButtonBackground: UIColor {
        asset("WeatherErrorButtonBackground")
    }

    static var weatherSunIcon: UIColor {
        asset("WeatherSunIcon")
    }

    static var weatherCloudIcon: UIColor {
        asset("WeatherCloudIcon")
    }

    static var weatherPrecipitationIcon: UIColor {
        asset("WeatherPrecipitationIcon")
    }

    static var weatherUVGradientColors: [UIColor] {
        [
            asset("WeatherUVLow"),
            asset("WeatherUVModerate"),
            asset("WeatherUVHigh"),
            asset("WeatherUVVeryHigh"),
            asset("WeatherUVExtreme")
        ]
    }

    // MARK: - City search

    static var citySearchMoreButtonBackground: UIColor {
        asset("CitySearchMoreButtonBackground")
    }

    static var citySearchMoreButtonBorder: UIColor {
        asset("CitySearchMoreButtonBorder")
    }

    private static func asset(_ name: String) -> UIColor {
        guard let color = UIColor(named: name) else {
            assertionFailure("Missing color asset: \(name)")
            return UIColor()
        }
        return color
    }
}

extension AppColors {

    // MARK: - Утро: 6:00–12:00
    enum Morning {
        static var top: UIColor { asset("GradientMorningTop") }
        static var bottom: UIColor { asset("GradientMorningBottom") }
    }

    // MARK: - День: 12:00–18:00
    enum Day {
        static var top: UIColor { asset("GradientDayTop") }
        static var middle: UIColor { asset("GradientDayMiddle") }
        static var bottom: UIColor { asset("GradientDayBottom") }
    }

    // MARK: - Вечер: 18:00–24:00
    enum Evening {
        static var top: UIColor { asset("GradientEveningTop") }
        static var bottom: UIColor { asset("GradientEveningBottom") }
    }

    // MARK: - Ночь: 0:00–6:00
    enum Night {
        static var top: UIColor { asset("GradientNightTop") }
        static var bottom: UIColor { asset("GradientNightBottom") }
    }

    // MARK: - Дождь
    enum Rain {
        static var dayTop: UIColor { asset("GradientRainDayTop") }
        static var dayBottom: UIColor { asset("GradientRainDayBottom") }
        static var nightTop: UIColor { asset("GradientRainNightTop") }
        static var nightBottom: UIColor { asset("GradientRainNightBottom") }
    }
}

enum AppHaptics {
    private static let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let deleteImpactGenerator = UIImpactFeedbackGenerator(style: .medium)

    static func prepareLightImpact() {
        lightImpactGenerator.prepare()
    }

    static func lightImpact() {
        lightImpactGenerator.impactOccurred()
        lightImpactGenerator.prepare()
    }

    static func deleteImpact() {
        deleteImpactGenerator.impactOccurred()
        deleteImpactGenerator.prepare()
    }
}
