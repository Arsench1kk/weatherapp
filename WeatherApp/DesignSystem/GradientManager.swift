import UIKit

final class GradientManager {

    static let shared = GradientManager()
    static let gradientLayerName = "weatherGradient"

    /// Применяет градиент к переданному слою.
    func applyGradient(to layer: CALayer, condition: WeatherCondition?, hour: Int) {
        let weatherId = condition?.id ?? 800
        applyGradient(to: layer, timeOfDay: timeOfDay(for: hour), isRaining: (200..<600).contains(weatherId))
    }

    func applyGradient(to layer: CALayer, timeOfDay: TimeOfDay, isRaining: Bool) {
        layer.sublayers?
            .filter { $0.name == Self.gradientLayerName }
            .forEach { $0.removeFromSuperlayer() }
        
        let colors = colors(for: timeOfDay, isRaining: isRaining)
        
        let gradient = CAGradientLayer()
        gradient.name = Self.gradientLayerName
        gradient.colors = colors.map { $0.cgColor }
        gradient.locations = (0..<colors.count).map {
            NSNumber(value: Double($0) / Double(colors.count - 1))
        }
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint   = CGPoint(x: 0.5, y: 1)
        gradient.frame      = layer.bounds
        gradient.zPosition  = -1
        
        if let firstSublayer = layer.sublayers?.first(where: { $0.name != Self.gradientLayerName }) {
            layer.insertSublayer(gradient, below: firstSublayer)
        } else {
            layer.insertSublayer(gradient, at: 0)
        }
    }

    private func timeOfDay(for hour: Int) -> TimeOfDay {
        switch hour {
        case 6..<12: return .morning
        case 12..<18: return .day
        case 18..<24: return .evening
        default: return .night
        }
    }

    func colors(for timeOfDay: TimeOfDay, isRaining: Bool) -> [UIColor] {
        switch timeOfDay {
        case .morning:
            return isRaining ? [
                AppColors.Rain.dayTop,
                AppColors.Rain.dayBottom
            ] : [
                AppColors.Morning.top,
                AppColors.Morning.bottom
            ]
        case .day:
            return isRaining ? [
                AppColors.Rain.dayTop,
                AppColors.Rain.dayBottom
            ] : [
                AppColors.Day.top,
                AppColors.Day.middle,
                AppColors.Day.bottom
            ]
        case .evening:
            return isRaining ? [
                AppColors.Rain.dayTop,
                AppColors.Rain.dayBottom
            ] : [
                AppColors.Evening.top,
                AppColors.Evening.bottom
            ]
        case .night:
            return isRaining ? [
                AppColors.Rain.nightTop,
                AppColors.Rain.nightBottom
            ] : [
                AppColors.Night.top,
                AppColors.Night.bottom
            ]
        }
    }
}
