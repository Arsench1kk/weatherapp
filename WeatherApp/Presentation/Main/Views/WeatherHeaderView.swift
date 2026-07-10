import UIKit
import SnapKit

final class WeatherHeaderView: UIView {

    // MARK: - UI

    private let locationIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "location.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .medium))
        iv.tintColor = WeatherCardStyle.primaryTextColor
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = WeatherCardStyle.primaryTextColor
        l.textAlignment = .center
        l.text = "РАБОТА"
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
        let l = UILabel()
        l.font = .systemFont(ofSize: 32, weight: .medium)
        l.textColor = WeatherCardStyle.primaryTextColor
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.75
        return l
    }()

    private let temperatureLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 92, weight: .thin)
        l.textColor = WeatherCardStyle.primaryTextColor
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.75
        return l
    }()

    private let descriptionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .medium)
        l.textColor = UIColor(red: 201 / 255, green: 1, blue: 250 / 255, alpha: 1)
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.75
        return l
    }()

    private let minMaxLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .medium)
        l.textColor = WeatherCardStyle.primaryTextColor
        l.textAlignment = .center
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
