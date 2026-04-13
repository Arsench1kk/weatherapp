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

