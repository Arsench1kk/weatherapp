import UIKit
import SnapKit

final class WeatherHeaderView: UIView {

    // MARK: - UI

    private let locationIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "location.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))?
            .withRenderingMode(.alwaysOriginal)
            .applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [AppColors.weatherIconPrimary]))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let locationLabel: UILabel = {
        let l = AppTextStyle.label(style: UIFont.systemFont(ofSize: 12, weight: .medium), color: AppColors.textPrimary, alignment: .center)
        l.text = nil
        return l
    }()

    private lazy var locationStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [locationIconView, locationLabel])
        sv.axis = .horizontal
        sv.spacing = 2
        sv.alignment = .center
        return sv
    }()

    private let cityLabel: UILabel = {
        let l = AppTextStyle.label(style: AppTextStyle.locationName, color: AppColors.textPrimary, alignment: .center)
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.75
        return l
    }()

    private let temperatureLabel: UILabel = {
        let l = AppTextStyle.label(style: AppTextStyle.currentTemp, color: AppColors.textPrimary, alignment: .center)
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.75
        return l
    }()

    private let descriptionLabel: UILabel = {
        let l = AppTextStyle.label(style: AppTextStyle.condition, color: AppColors.textPrimary, alignment: .center)
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.75
        return l
    }()

    private let minMaxLabel: UILabel = {
        let l = AppTextStyle.label(style: AppTextStyle.condition, color: AppColors.textSecondary, alignment: .center)
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.75
        return l
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
