import UIKit

final class CityWeatherCardBackgroundView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let cloudLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        cloudLayer.frame = bounds.insetBy(dx: -bounds.width * 0.15, dy: -bounds.height * 0.15)
    }

    func configure(theme: WeatherTheme) {
        let baseColors = GradientManager.shared.colors(
            for: theme.timeOfDay,
            isRaining: theme.isRaining
        )
        let cardColors = baseColors.map { color in
            Self.mixedColor(color, with: .black, amount: theme.timeOfDay == .night ? 0.26 : 0.32)
        }

        gradientLayer.colors = cardColors.map { $0.withAlphaComponent(0.92).cgColor }
        cloudLayer.opacity = theme.timeOfDay == .day ? 0.34 : 0.48
        cloudLayer.colors = Self.cloudColors(for: theme)
    }

    private func setupLayers() {
        backgroundColor = UIColor(red: 15 / 255, green: 18 / 255, blue: 32 / 255, alpha: 1)
        clipsToBounds = true

        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.1)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        layer.addSublayer(gradientLayer)

        cloudLayer.locations = [0.0, 0.34, 0.58, 1.0]
        cloudLayer.startPoint = CGPoint(x: 0.0, y: 0.35)
        cloudLayer.endPoint = CGPoint(x: 1.0, y: 0.7)
        layer.addSublayer(cloudLayer)

        configure(theme: .current)
    }

    private static func cloudColors(for theme: WeatherTheme) -> [CGColor] {
        let highlightAlpha: CGFloat
        let tailAlpha: CGFloat

        switch theme.timeOfDay {
        case .morning:
            highlightAlpha = 0.16
            tailAlpha = 0.06
        case .day:
            highlightAlpha = 0.12
            tailAlpha = 0.05
        case .evening:
            highlightAlpha = 0.14
            tailAlpha = 0.05
        case .night:
            highlightAlpha = 0.10
            tailAlpha = 0.04
        }

        return [
            UIColor.white.withAlphaComponent(0.00).cgColor,
            UIColor.white.withAlphaComponent(theme.isRaining ? highlightAlpha * 0.72 : highlightAlpha).cgColor,
            UIColor.white.withAlphaComponent(tailAlpha).cgColor,
            UIColor.white.withAlphaComponent(0.00).cgColor
        ]
    }

    private static func mixedColor(_ firstColor: UIColor, with secondColor: UIColor, amount: CGFloat) -> UIColor {
        var firstRed: CGFloat = 0
        var firstGreen: CGFloat = 0
        var firstBlue: CGFloat = 0
        var firstAlpha: CGFloat = 0
        var secondRed: CGFloat = 0
        var secondGreen: CGFloat = 0
        var secondBlue: CGFloat = 0
        var secondAlpha: CGFloat = 0

        guard firstColor.getRed(&firstRed, green: &firstGreen, blue: &firstBlue, alpha: &firstAlpha),
              secondColor.getRed(&secondRed, green: &secondGreen, blue: &secondBlue, alpha: &secondAlpha) else {
            return firstColor
        }

        let clampedAmount = min(max(amount, 0), 1)
        let inverseAmount = 1 - clampedAmount

        return UIColor(
            red: firstRed * inverseAmount + secondRed * clampedAmount,
            green: firstGreen * inverseAmount + secondGreen * clampedAmount,
            blue: firstBlue * inverseAmount + secondBlue * clampedAmount,
            alpha: firstAlpha * inverseAmount + secondAlpha * clampedAmount
        )
    }
}
