import UIKit
import SnapKit

enum WeatherCardStyle {

    static let cornerRadius: CGFloat = 22
    static let sectionSpacing: CGFloat = 8
    static let interItemSpacing: CGFloat = 10
    static let contentInsets = UIEdgeInsets(top: 16, left: 18, bottom: 16, right: 18)
    private static var currentTheme = WeatherCardTheme(timeOfDay: .current(), isRaining: false)

    static let primaryTextColor = AppColors.textPrimary
    static let secondaryTextColor = AppColors.textPrimary.withAlphaComponent(0.68)
    static let titleColor = AppColors.textPrimary.withAlphaComponent(0.55)
    static let iconTintColor = AppColors.textPrimary.withAlphaComponent(0.50)

    static let separatorColor = AppColors.textPrimary.withAlphaComponent(0.22)

    static func makeContainerView() -> UIView {
        let containerView = WeatherCardContainerView()
        containerView.apply(theme: currentTheme)
        return containerView
    }

    static func makeSeparator() -> UIView {
        let separatorView = WeatherSeparatorView()
        separatorView.apply(theme: currentTheme)
        separatorView.snp.makeConstraints { make in
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        return separatorView
    }

    static func applyTheme(to rootView: UIView, timeOfDay: TimeOfDay, isRaining: Bool) {
        currentTheme = WeatherCardTheme(timeOfDay: timeOfDay, isRaining: isRaining)
        applyThemeRecursively(to: rootView, theme: currentTheme)
    }

    private static func applyThemeRecursively(to view: UIView, theme: WeatherCardTheme) {
        if let cardContainerView = view as? WeatherCardContainerView {
            cardContainerView.apply(theme: theme)
        } else if let separatorView = view as? WeatherSeparatorView {
            separatorView.apply(theme: theme)
        }

        view.subviews.forEach { childView in
            applyThemeRecursively(to: childView, theme: theme)
        }
    }
}

private struct WeatherCardTheme {
    let timeOfDay: TimeOfDay
    let isRaining: Bool

    var fallbackFillColor: UIColor {
        if isRaining {
            return UIColor.black.withAlphaComponent(timeOfDay == .night ? 0.22 : 0.16)
        }

        switch timeOfDay {
        case .morning:
            return UIColor.black.withAlphaComponent(0.13)
        case .day:
            return UIColor.black.withAlphaComponent(0.11)
        case .evening:
            return UIColor.black.withAlphaComponent(0.15)
        case .night:
            return UIColor.black.withAlphaComponent(0.20)
        }
    }

    var borderColor: UIColor {
        UIColor.white.withAlphaComponent(timeOfDay == .night ? 0.10 : 0.13)
    }

    var separatorColor: UIColor {
        UIColor.white.withAlphaComponent(0.24)
    }
}

private final class WeatherCardContainerView: UIView {

    private let tintOverlayView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tintOverlayView.frame = bounds
    }

    func apply(theme: WeatherCardTheme) {
        tintOverlayView.backgroundColor = theme.fallbackFillColor
        layer.borderColor = theme.borderColor.cgColor
    }

    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = true
        layer.cornerRadius = WeatherCardStyle.cornerRadius
        layer.borderWidth = 1.0 / UIScreen.main.scale
        layer.cornerCurve = .continuous

        tintOverlayView.isUserInteractionEnabled = false

        addSubview(tintOverlayView)
        sendSubviewToBack(tintOverlayView)
    }
}

private final class WeatherSeparatorView: UIView {
    func apply(theme: WeatherCardTheme) {
        backgroundColor = theme.separatorColor
    }
}
