import UIKit
import SnapKit

final class CityWeatherCardCell: UITableViewCell {

    static let reuseIdentifier = "CityWeatherCardCell"

    private let cardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 26
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        return view
    }()

    private let backgroundViewForCard = CityWeatherCardBackgroundView()

    private let locationImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "house.fill"))
        imageView.tintColor = AppColors.textPrimary.withAlphaComponent(0.58)
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private let titleLabel = AppTextStyle.label(
        style: .systemFont(ofSize: 27, weight: .bold),
        color: AppColors.textPrimary
    )

    private let subtitleLabel = AppTextStyle.label(
        style: .systemFont(ofSize: 17, weight: .semibold),
        color: AppColors.textPrimary.withAlphaComponent(0.58)
    )

    private let temperatureLabel = AppTextStyle.label(
        style: .systemFont(ofSize: 58, weight: .thin),
        color: AppColors.textPrimary,
        alignment: .right
    )

    private let conditionLabel = AppTextStyle.label(
        style: .systemFont(ofSize: 17, weight: .semibold),
        color: AppColors.textPrimary.withAlphaComponent(0.62)
    )

    private let highLowLabel = AppTextStyle.label(
        style: .systemFont(ofSize: 17, weight: .bold),
        color: AppColors.textPrimary,
        alignment: .right
    )

    private let weatherImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = AppColors.textPrimary.withAlphaComponent(0.72)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let activityIndicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.color = AppColors.textPrimary.withAlphaComponent(0.72)
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
        weatherImageView.image = nil
    }

    func configure(with model: CityWeatherPreviewUIModel) {
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        locationImageView.isHidden = !model.isCurrentLocation
        backgroundViewForCard.configure(theme: model.theme)

        switch model.state {
        case .loading:
            temperatureLabel.text = "--"
            conditionLabel.text = "Загрузка"
            highLowLabel.text = "H:--  L:--"
            weatherImageView.isHidden = true
            activityIndicatorView.startAnimating()

        case .loaded(let temperature, let description, let symbolName, let highLow):
            temperatureLabel.text = temperature
            conditionLabel.text = description
            highLowLabel.text = highLow
            weatherImageView.image = UIImage(systemName: symbolName)
            weatherImageView.isHidden = false
            activityIndicatorView.stopAnimating()

        case .error(let message):
            temperatureLabel.text = "--"
            conditionLabel.text = message
            highLowLabel.text = "H:--  L:--"
            weatherImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
            weatherImageView.isHidden = false
            activityIndicatorView.stopAnimating()
        }
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview()
        }

        cardView.addSubview(backgroundViewForCard)
        backgroundViewForCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let subtitleStackView = UIStackView(arrangedSubviews: [subtitleLabel, locationImageView])
        subtitleStackView.axis = .horizontal
        subtitleStackView.spacing = 6
        subtitleStackView.alignment = .center

        let leftStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleStackView, UIView(), conditionLabel])
        leftStackView.axis = .vertical
        leftStackView.spacing = 4

        let iconContainerView = UIView()
        iconContainerView.addSubview(weatherImageView)
        iconContainerView.addSubview(activityIndicatorView)

        weatherImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }

        activityIndicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let rightStackView = UIStackView(arrangedSubviews: [temperatureLabel, UIView(), highLowLabel])
        rightStackView.axis = .vertical
        rightStackView.spacing = 4
        rightStackView.alignment = .trailing

        [leftStackView, iconContainerView, rightStackView].forEach(cardView.addSubview)

        locationImageView.snp.makeConstraints { make in
            make.size.equalTo(15)
        }

        leftStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.bottom.equalToSuperview().inset(22)
            make.trailing.lessThanOrEqualTo(rightStackView.snp.leading).offset(-14)
        }

        iconContainerView.snp.makeConstraints { make in
            make.leading.equalTo(leftStackView.snp.trailing).offset(10)
            make.bottom.equalToSuperview().inset(20)
            make.size.equalTo(32)
        }

        rightStackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.top.bottom.equalToSuperview().inset(18)
            make.width.equalTo(138)
        }
    }
}
