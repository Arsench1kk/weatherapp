import UIKit

enum AppColors {
    
    // MARK: - Backgrounds
    
    static var backgroundPrimary: UIColor {
        UIColor(named: "BackgroundPrimary") ?? .white
    }
    
    static var backgroundSecondary: UIColor {
        UIColor(named: "BackgroundSecondary") ?? .systemBackground
    }
    
    // MARK: - Text
    
    static var textPrimary: UIColor {
        UIColor(named: "TextPrimary") ?? .label
    }
    
    static var textSecondary: UIColor {
        UIColor(named: "TextSecondary") ?? .secondaryLabel
    }
    
    // MARK: - Accent
    
    static var accentBlue: UIColor {
        UIColor(named: "AccentBlue") ?? .systemBlue
    }
    
    // MARK: - Weather specific
    
    static var weatherCardBackground: UIColor {
        UIColor(named: "WeatherCardBackground") ?? UIColor.white.withAlphaComponent(0.15)
    }
}

extension AppColors {

    // MARK: - Утро: 6:00–12:00
    enum Morning {
        static let top    = UIColor(named: "GradientMorningTop")
        static let bottom = UIColor(named: "GradientMorningBottom")
    }

    // MARK: - День: 12:00–18:00
    enum Day {
        static let top    = UIColor(named: "GradientDayTop")
        static let middle = UIColor(named: "GradientDayMiddle")
        static let bottom = UIColor(named: "GradientDayBottom")
    }

    // MARK: - Вечер: 18:00–24:00
    enum Evening {
        static let top    = UIColor(named: "GradientEveningTop")
        static let bottom = UIColor(named: "GradientEveningBottom")
    }

    // MARK: - Ночь: 0:00–6:00
    enum Night {
        static let top    = UIColor(named: "GradientNightTop")
        static let bottom = UIColor(named: "GradientNightBottom")
    }

    // MARK: - Дождь
    enum Rain {
        static let dayTop      = UIColor(named: "GradientRainDayTop")
        static let dayBottom   = UIColor(named: "GradientRainDayBottom")
        static let nightTop    = UIColor(named: "GradientRainNightTop")
        static let nightBottom = UIColor(named: "GradientRainNightBottom")
    }
}

