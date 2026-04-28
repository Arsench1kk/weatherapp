import UIKit
import SnapKit

enum WeatherCardStyle {

    static let cornerRadius: CGFloat = 24
    static let sectionSpacing: CGFloat = 10
    static let interItemSpacing: CGFloat = 10
    static let contentInsets = UIEdgeInsets(top: 18, left: 20, bottom: 18, right: 20)

    static let primaryTextColor = AppColors.textPrimary
    static let secondaryTextColor = AppColors.textPrimary.withAlphaComponent(0.68)
    static let titleColor = AppColors.textPrimary.withAlphaComponent(0.55)
    static let iconTintColor = AppColors.textPrimary.withAlphaComponent(0.50)

    static let separatorColor = AppColors.textPrimary.withAlphaComponent(0.14)

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
        sep.snp.makeConstraints { make in
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        return sep
    }
}
