import UIKit
import SnapKit

final class WeatherHeaderView: UIView {

    // MARK: - UI

    private let locationIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "location.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))?
            .withRenderingMode(.alwaysTemplate)
        imageView.tintColor = WeatherCardStyle.iconTintColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let locationLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 12, weight: .medium), color: WeatherCardStyle.titleColor, alignment: .center)
        label.text = nil
        return label
    }()

    private lazy var locationStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [locationIconView, locationLabel])
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.alignment = .center
        return stackView
    }()

    private let cityLabel: UILabel = {
        let label = AppTextStyle.label(style: AppTextStyle.locationName, color: AppColors.textPrimary, alignment: .center)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    private let temperatureLabel: UILabel = {
        let label = AppTextStyle.label(style: AppTextStyle.currentTemp, color: AppColors.textPrimary, alignment: .center)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = AppTextStyle.label(style: AppTextStyle.condition, color: AppColors.textPrimary, alignment: .center)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    private let minMaxLabel: UILabel = {
        let label = AppTextStyle.label(style: AppTextStyle.condition, color: AppColors.textSecondary, alignment: .center)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupUI() {
        [locationStackView, cityLabel, temperatureLabel, descriptionLabel, minMaxLabel]
            .forEach { addSubview($0) }

        locationIconView.snp.makeConstraints { make in
            make.size.equalTo(12)
        }

        locationStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        cityLabel.snp.makeConstraints { make in
            make.top.equalTo(locationStackView.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        temperatureLabel.snp.makeConstraints { make in
            make.top.equalTo(cityLabel.snp.bottom).offset(0)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(temperatureLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        minMaxLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(0)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }

    // MARK: - Configure

    func configure(with model: MainWeatherUIModel) {
        cityLabel.text = model.cityName
        temperatureLabel.text = model.temperature
        descriptionLabel.text = model.description
        minMaxLabel.text = model.minMaxTemp
    }
}
