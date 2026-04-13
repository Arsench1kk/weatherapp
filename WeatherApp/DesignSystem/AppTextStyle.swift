import UIKit

enum AppTextStyle {
    
    // MARK: - Cases
    
    case largeTitle       // 96pt — большая температура
    case title1           // 34pt — название города
    case title2           // 28pt — заголовок секции
    case title3           // 22pt — подзаголовок
    case headline         // 17pt bold — акцентный текст
    case body             // 17pt — основной текст
    case callout          // 16pt — описание погоды
    case subheadline      // 15pt — мелкие подписи
    case footnote         // 13pt — сноски
    case caption1         // 12pt — подписи к иконкам
    case caption2         // 11pt — минимальный текст
    
    // MARK: - Font
    
    var font: UIFont {
        switch self {
        case .largeTitle:
            return UIFont.systemFont(ofSize: 96, weight: .thin)
        case .title1:
            return UIFont.systemFont(ofSize: 34, weight: .regular)
        case .title2:
            return UIFont.systemFont(ofSize: 28, weight: .bold)
        case .title3:
            return UIFont.systemFont(ofSize: 22, weight: .semibold)
        case .headline:
            return UIFont.systemFont(ofSize: 17, weight: .semibold)
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
    
    // MARK: - Default Color
    
    var defaultColor: UIColor {
        switch self {
        case .largeTitle, .title1, .title2, .title3, .headline:
            return AppColors.textPrimary
        default:
            return AppColors.textSecondary
        }
    }
}

// MARK: - UILabel Extension

extension UILabel {
    func applyStyle(_ style: AppTextStyle, color: UIColor? = nil) {
        self.font = style.font
        self.textColor = color ?? style.defaultColor
    }
}

