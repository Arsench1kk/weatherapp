import UIKit
import SnapKit

final class WeatherErrorView: UIView {

    var onRetry: (() -> Void)?

    private let iconLabel: UILabel = {
        let label = UILabel()
        label.text = "⚠️"
        label.font = .systemFont(ofSize: 48)
        label.textAlignment = .center
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Повторить", for: .normal)
        button.setTitleColor(AppColors.textPrimary, for: .normal)
        button.backgroundColor = AppColors.weatherErrorButtonBackground
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.accessibilityLabel = "Повторить загрузку"
        button.accessibilityHint = "Повторяет запрос погоды"
        button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        let stackView = UIStackView(arrangedSubviews: [iconLabel, messageLabel, retryButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }

        retryButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.width.greaterThanOrEqualTo(140)
        }
        iconLabel.isAccessibilityElement = false
        messageLabel.accessibilityTraits = [.staticText]
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with message: String) {
        messageLabel.text = message
        messageLabel.accessibilityLabel = "Ошибка. \(message)"
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
