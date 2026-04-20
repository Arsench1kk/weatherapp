import UIKit
import SnapKit

final class WeatherHeaderView: UIView {

    // MARK: - UI

    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .white.withAlphaComponent(0.8)
        l.textAlignment = .center
        l.text = "▼ РАБОТА"
        return l
    }()

    private let cityLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 36, weight: .light)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let temperatureLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 96, weight: .thin)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let descriptionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let minMaxLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
        l.textColor = .white
        l.textAlignment = .center
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
        [locationLabel, cityLabel, temperatureLabel, descriptionLabel, minMaxLabel]
            .forEach { addSubview($0) }

        locationLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(20)
            make.centerX.equalToSuperview()
        }

        cityLabel.snp.makeConstraints { make in
            make.top.equalTo(locationLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        temperatureLabel.snp.makeConstraints { make in
            make.top.equalTo(cityLabel.snp.bottom).offset(-8)
            make.centerX.equalToSuperview()
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(temperatureLabel.snp.bottom).offset(-8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        minMaxLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(20)
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
