import UIKit

enum AppTextStyle {
    
    static let currentTemp = UIFont.systemFont(ofSize: 96, weight: .thin)
    static let locationName = UIFont.systemFont(ofSize: 28, weight: .regular)
    static let condition = UIFont.systemFont(ofSize: 17, weight: .medium)
    static let weatherCardTitle = UIFont.systemFont(ofSize: 12, weight: .medium)
    static let weatherMetricValue = UIFont.systemFont(ofSize: 32, weight: .regular)
    static let weatherCardBody = UIFont.systemFont(ofSize: 14, weight: .regular)
    
    static func label(style: UIFont, color: UIColor = AppColors.textPrimary, alignment: NSTextAlignment = .natural) -> UILabel {
        let label = UILabel()
        label.font = style
        label.textColor = color
        label.textAlignment = alignment
        return label
    }
    
    // Поддержка старых стилей для обратной совместимости, если где-то еще остались
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption1
    case caption2
    
    var font: UIFont {
        switch self {
        case .largeTitle:
            return AppTextStyle.currentTemp
        case .title1:
            return AppTextStyle.locationName
        case .title2:
            return UIFont.systemFont(ofSize: 28, weight: .bold)
        case .title3:
            return UIFont.systemFont(ofSize: 22, weight: .semibold)
        case .headline:
            return AppTextStyle.condition
        case .body:
            return UIFont.systemFont(ofSize: 17, weight: .regular)
        case .callout:
            return UIFont.systemFont(ofSize: 16, weight: .regular)
        case .subheadline:
            return UIFont.systemFont(ofSize: 15, weight: .regular)
        case .footnote:
            return UIFont.systemFont(ofSize: 13, weight: .regular)
        case .caption1:
            return UIFont.systemFont(ofSize: 12, weight: .regular)
        case .caption2:
            return UIFont.systemFont(ofSize: 11, weight: .regular)
        }
    }
    
    var defaultColor: UIColor {
        return AppColors.textPrimary
    }
}

extension UILabel {
    func applyStyle(_ style: AppTextStyle, color: UIColor? = nil) {
        self.font = style.font
        self.textColor = color ?? style.defaultColor
    }
}
