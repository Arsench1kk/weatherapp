import UIKit
import SnapKit

final class SearchTextField: UIView {

    var onTextChanged: ((String) -> Void)?
    var onClear: (() -> Void)?

    private let searchImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        imageView.tintColor = AppColors.textPrimary.withAlphaComponent(0.88)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Search for a city or airport"
        textField.textColor = AppColors.textPrimary
        textField.tintColor = AppColors.textPrimary
        textField.font = .systemFont(ofSize: 19, weight: .regular)
        textField.autocorrectionType = .no
        textField.returnKeyType = .search
        textField.attributedPlaceholder = NSAttributedString(
            string: "Search for a city or airport",
            attributes: [.foregroundColor: AppColors.textPrimary.withAlphaComponent(0.58)]
        )
        textField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
        return textField
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = AppColors.textPrimary.withAlphaComponent(0.45)
        button.isHidden = true
        button.addTarget(self, action: #selector(handleClear), for: .touchUpInside)
        return button
    }()

    private let microphoneImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "mic.fill"))
        imageView.tintColor = AppColors.textPrimary.withAlphaComponent(0.9)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func focus() {
        textField.becomeFirstResponder()
    }

    private func setupUI() {
        let containerView = UIView()
        containerView.backgroundColor = UIColor(red: 28 / 255, green: 32 / 255, blue: 55 / 255, alpha: 0.92)
        containerView.layer.cornerRadius = 25
        containerView.layer.cornerCurve = .continuous
        containerView.layer.borderWidth = 1.0
        containerView.layer.borderColor = UIColor(red: 91 / 255, green: 101 / 255, blue: 159 / 255, alpha: 0.58).cgColor
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(50)
        }

        [searchImageView, textField, microphoneImageView, clearButton].forEach(containerView.addSubview)

        searchImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.centerY.equalToSuperview()
            make.size.equalTo(23)
        }

        clearButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
            make.size.equalTo(30)
        }

        microphoneImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(18)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }

        textField.snp.makeConstraints { make in
            make.leading.equalTo(searchImageView.snp.trailing).offset(14)
            make.trailing.equalTo(microphoneImageView.snp.leading).offset(-12)
            make.top.bottom.equalToSuperview()
        }
    }

    @objc private func handleTextChanged() {
        let text = textField.text ?? ""
        clearButton.isHidden = text.isEmpty
        microphoneImageView.isHidden = !text.isEmpty
        onTextChanged?(text)
    }

    @objc private func handleClear() {
        textField.text = ""
        clearButton.isHidden = true
        microphoneImageView.isHidden = false
        onClear?()
    }
}
