import UIKit

final class GradientManager {

    /// Возвращает массив цветов для градиента по времени суток и погоде
    static func colors(for timeOfDay: TimeOfDay, isRaining: Bool) -> [UIColor] {
        isRaining ? rainColors(for: timeOfDay) : clearColors(for: timeOfDay)
    }

    // MARK: - Ясная погода

    private static func clearColors(for timeOfDay: TimeOfDay) -> [UIColor] {
        switch timeOfDay {
        case .morning:
            return [
                AppColors.Morning.top    ?? UIColor(red: 0.29, green: 0.56, blue: 0.77, alpha: 1),
                AppColors.Morning.bottom ?? UIColor(red: 0.50, green: 0.70, blue: 0.85, alpha: 1)
            ]
        case .day:
            return [
                AppColors.Day.top    ?? UIColor(red: 0.12, green: 0.43, blue: 0.77, alpha: 1),
                AppColors.Day.middle ?? UIColor(red: 0.17, green: 0.56, blue: 0.83, alpha: 1),
                AppColors.Day.bottom ?? UIColor(red: 0.29, green: 0.69, blue: 0.88, alpha: 1)
            ]
        case .evening:
            return [
                AppColors.Evening.top    ?? UIColor(red: 0.10, green: 0.25, blue: 0.42, alpha: 1),
                AppColors.Evening.bottom ?? UIColor(red: 0.23, green: 0.43, blue: 0.66, alpha: 1)
            ]
        case .night:
            return [
                AppColors.Night.top    ?? UIColor(red: 0.05, green: 0.11, blue: 0.17, alpha: 1),
                AppColors.Night.bottom ?? UIColor(red: 0.11, green: 0.23, blue: 0.37, alpha: 1)
            ]
        }
    }

    // MARK: - Дождливая погода

    private static func rainColors(for timeOfDay: TimeOfDay) -> [UIColor] {
        switch timeOfDay {
        case .morning, .day, .evening:
            return [
                AppColors.Rain.dayTop    ?? UIColor(red: 0.23, green: 0.38, blue: 0.50, alpha: 1),
                AppColors.Rain.dayBottom ?? UIColor(red: 0.35, green: 0.54, blue: 0.67, alpha: 1)
            ]
        case .night:
            return [
                AppColors.Rain.nightTop    ?? UIColor(red: 0.10, green: 0.17, blue: 0.22, alpha: 1),
                AppColors.Rain.nightBottom ?? UIColor(red: 0.17, green: 0.29, blue: 0.37, alpha: 1)
            ]
        }
    }
}

// MARK: - UIView extension

extension UIView {

    func applyGradient(colors: [UIColor]) {
        // Удаляем старый градиент если есть
        layer.sublayers?
            .filter { $0 is CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }

        let gradient = CAGradientLayer()
        gradient.colors = colors.map { $0.cgColor }
        gradient.locations = (0..<colors.count).map {
            NSNumber(value: Double($0) / Double(colors.count - 1))
        }
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint   = CGPoint(x: 0.5, y: 1)
        gradient.frame      = bounds

        layer.insertSublayer(gradient, at: 0)
    }
}
