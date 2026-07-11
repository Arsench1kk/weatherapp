import UIKit
import SnapKit

final class WeatherErrorView: UIView {

    var onRetry: (() -> Void)?

    private let iconLabel: UILabel = {
        let l = UILabel()
        l.text = "⚠️"
        l.font = .systemFont(ofSize: 48)
        l.textAlignment = .center
        return l
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
        l.textColor = AppColors.textPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private lazy var retryButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Повторить", for: .normal)
        btn.setTitleColor(AppColors.textPrimary, for: .normal)
        btn.backgroundColor = AppColors.weatherErrorButtonBackground
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        btn.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        let stack = UIStackView(arrangedSubviews: [iconLabel, messageLabel, retryButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }

        retryButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.width.greaterThanOrEqualTo(140)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with message: String) {
        messageLabel.text = message
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
