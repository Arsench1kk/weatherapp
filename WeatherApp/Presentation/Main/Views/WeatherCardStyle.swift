import UIKit
import SnapKit

enum WeatherCardStyle {
    static let backgroundColor = UIColor(red: 55 / 255, green: 125 / 255, blue: 195 / 255, alpha: 1)
    static let cornerRadius: CGFloat = 12
    static let contentInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    static let sectionSpacing: CGFloat = 8
    static let titleColor = UIColor.white.withAlphaComponent(0.52)
    static let primaryTextColor = UIColor(red: 1, green: 251 / 255, blue: 252 / 255, alpha: 1)
    static let secondaryTextColor = UIColor(red: 1, green: 251 / 255, blue: 252 / 255, alpha: 0.52)
    static let separatorColor = UIColor.white.withAlphaComponent(0.2)
    static let accentMint = UIColor(red: 96 / 255, green: 218 / 255, blue: 207 / 255, alpha: 1)

    static func makeContainerView() -> UIView {
        let view = UIView()
        view.backgroundColor = backgroundColor
        view.layer.cornerRadius = cornerRadius
        view.clipsToBounds = true
        return view
    }

    static func makeSectionTitle(iconName: String, title: String) -> UIStackView {
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: iconName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))
        iconView.tintColor = titleColor
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { $0.size.equalTo(16) }

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = titleColor
        label.numberOfLines = 1

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }

    static func makeSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = separatorColor
        separator.snp.makeConstraints { $0.height.equalTo(1) }
        return separator
    }
}
