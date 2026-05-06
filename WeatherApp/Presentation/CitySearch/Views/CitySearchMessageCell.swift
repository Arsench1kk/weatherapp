import UIKit
import SnapKit

final class CitySearchMessageCell: UITableViewCell {

    static let reuseIdentifier = "CitySearchMessageCell"

    private let messageLabel = AppTextStyle.label(
        style: .systemFont(ofSize: 15, weight: .medium),
        color: AppColors.textPrimary.withAlphaComponent(0.62),
        alignment: .center
    )

    private let activityIndicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.color = AppColors.textPrimary.withAlphaComponent(0.62)
        indicatorView.isHidden = true
        return indicatorView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        activityIndicatorView.stopAnimating()
        activityIndicatorView.isHidden = true
    }

    func configure(message: String, showsLoading: Bool = false) {
        messageLabel.text = message
        activityIndicatorView.isHidden = !showsLoading

        if showsLoading {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        let stackView = UIStackView(arrangedSubviews: [activityIndicatorView, messageLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.distribution = .fill

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(16)
            make.leading.greaterThanOrEqualToSuperview().offset(18)
            make.trailing.lessThanOrEqualToSuperview().inset(18)
        }
    }
}
