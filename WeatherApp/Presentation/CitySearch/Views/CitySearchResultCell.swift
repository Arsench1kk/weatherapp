import UIKit
import SnapKit

final class CitySearchResultCell: UITableViewCell {

    static let reuseIdentifier = "CitySearchResultCell"

    private let titleLabel = AppTextStyle.label(
        style: .systemFont(ofSize: 17, weight: .regular),
        color: AppColors.textPrimary
    )

    private let subtitleLabel = AppTextStyle.label(
        style: .systemFont(ofSize: 13, weight: .regular),
        color: AppColors.textPrimary.withAlphaComponent(0.58)
    )

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with model: CitySearchSuggestionUIModel) {
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        accessibilityLabel = model.subtitle.isEmpty
            ? model.title
            : "\(model.title), \(model.subtitle)"
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        isAccessibilityElement = true
        accessibilityTraits = [.button]
        contentView.isAccessibilityElement = false

        let textStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 3

        contentView.addSubview(textStackView)

        textStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().inset(18)
            make.top.bottom.equalToSuperview().inset(11)
        }
    }
}
