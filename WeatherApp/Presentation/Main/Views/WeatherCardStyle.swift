import UIKit

enum WeatherCardStyle {

    static let cornerRadius: CGFloat = 12
    static let sectionSpacing: CGFloat = 8
    static let contentInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

    static let primaryTextColor = AppColors.textPrimary
    static let secondaryTextColor = AppColors.textSecondary
    static let titleColor = AppColors.textSecondary

    static let separatorColor = AppColors.weatherSeparator

    static func makeContainerView() -> UIView {
        let view = UIView()
        view.backgroundColor = AppColors.weatherCardBackground
        view.layer.cornerRadius = cornerRadius
        view.clipsToBounds = true
        return view
    }

    static func makeSeparator() -> UIView {
        let sep = UIView()
        sep.backgroundColor = separatorColor
        return sep
    }
}
