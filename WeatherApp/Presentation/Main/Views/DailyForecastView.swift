import UIKit
import SnapKit

final class DailyForecastView: UIView {

    private let containerView = WeatherCardStyle.makeContainerView()

    private let headerLabel = AppTextStyle.label(
        style: AppTextStyle.weatherCardTitle,
        color: WeatherCardStyle.titleColor
    )

    private lazy var headerStack: UIStackView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "calendar", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))?
            .withRenderingMode(.alwaysTemplate)
        iv.tintColor = WeatherCardStyle.iconTintColor
        iv.contentMode = .scaleAspectFit
        iv.snp.makeConstraints { $0.size.equalTo(14) }

        let sv = UIStackView(arrangedSubviews: [iv, headerLabel])
        sv.axis = .horizontal
        sv.spacing = 4
        sv.alignment = .center
        return sv
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        addSubview(containerView)
        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let headerWrapper = UIView()
        headerWrapper.addSubview(headerStack)
        headerStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(14)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        let mainStack = UIStackView(arrangedSubviews: [
            headerWrapper,
            WeatherCardStyle.makeSeparator(),
            stackView
        ])
        mainStack.axis = .vertical
        
        containerView.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with items: [DailyForecastUIModel]) {
        headerLabel.text = "ПРОГНОЗ НА \(items.count) ДНЕЙ"
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, item) in items.enumerated() {
            let row = DailyForecastRow()
            row.configure(with: item)
            stackView.addArrangedSubview(row)

            if index < items.count - 1 {
                let sepWrapper = UIView()
                let sep = WeatherCardStyle.makeSeparator()
                sepWrapper.addSubview(sep)
                sep.snp.makeConstraints { make in
                    make.top.bottom.equalToSuperview()
                    make.leading.trailing.equalToSuperview().inset(20)
                }
                stackView.addArrangedSubview(sepWrapper)
                sepWrapper.snp.makeConstraints { $0.height.equalTo(1.0 / UIScreen.main.scale) }
            }
        }
    }
}

// MARK: - Row

private final class DailyForecastRow: UIView {

    private let dayLabel: UILabel = {
        let l = AppTextStyle.label(style: UIFont.systemFont(ofSize: 18, weight: .regular), color: AppColors.textPrimary)
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.9
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let minTempLabel: UILabel = {
        let l = AppTextStyle.label(style: UIFont.systemFont(ofSize: 18, weight: .regular), color: WeatherCardStyle.secondaryTextColor)
        l.textAlignment = .right
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    private let barContainer = UIView()

    private let maxTempLabel: UILabel = {
        let l = AppTextStyle.label(style: UIFont.systemFont(ofSize: 18, weight: .regular), color: AppColors.textPrimary)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    private var currentModel: DailyForecastUIModel?
    private let bgLayer = CALayer()
    private let gradientLayer = CAGradientLayer()
    private let markerLayer = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayers()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayers() {
        bgLayer.backgroundColor = AppColors.weatherTemperatureBarTrack.cgColor
        bgLayer.cornerRadius = 2
        barContainer.layer.addSublayer(bgLayer)

        gradientLayer.cornerRadius = 2
        gradientLayer.colors = [
            AppColors.weatherTemperatureBarStart.cgColor,
            AppColors.weatherTemperatureBarEnd.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        barContainer.layer.addSublayer(gradientLayer)
        
        markerLayer.backgroundColor = AppColors.weatherTemperatureMarker.cgColor
        markerLayer.cornerRadius = 4
        markerLayer.borderWidth = 2
        markerLayer.borderColor = AppColors.weatherTemperatureMarkerBorder.cgColor
        markerLayer.isHidden = true
        barContainer.layer.addSublayer(markerLayer)
    }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [
            dayLabel, iconView, minTempLabel, barContainer, maxTempLabel
        ])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        addSubview(stack)

        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 11, left: 20, bottom: 11, right: 20))
        }

        dayLabel.snp.makeConstraints    { $0.width.equalTo(74) }
        iconView.snp.makeConstraints    { $0.size.equalTo(26) }
        minTempLabel.snp.makeConstraints { $0.width.equalTo(36) }
        maxTempLabel.snp.makeConstraints { $0.width.equalTo(36) }
        barContainer.snp.makeConstraints {
            $0.height.equalTo(4)
            $0.width.greaterThanOrEqualTo(40)
        }
    }

    func configure(with model: DailyForecastUIModel) {
        currentModel = model
        dayLabel.text    = model.dayName
        minTempLabel.text = "\(model.minTemp)°"
        maxTempLabel.text = "\(model.maxTemp)°"

        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        iconView.image = UIImage(systemName: model.symbolName, withConfiguration: config)?
            .withRenderingMode(.alwaysOriginal)
            .applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [
                AppColors.weatherSunIcon,
                AppColors.weatherCloudIcon,
                AppColors.weatherPrecipitationIcon
            ]))

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let model = currentModel else { return }
        
        let width = barContainer.bounds.width
        guard width > 0 else { return }

        let globalRange = Double(model.globalMax - model.globalMin)
        guard globalRange > 0 else { return }

        let startRatio = CGFloat(model.minTemp - model.globalMin) / CGFloat(globalRange)
        let endRatio   = CGFloat(model.maxTemp - model.globalMin) / CGFloat(globalRange)

        let h: CGFloat = 4
        
        bgLayer.frame = CGRect(x: 0, y: 0, width: width, height: h)

        let barX = startRatio * width
        let barW = max((endRatio - startRatio) * width, 8)
        gradientLayer.frame = CGRect(x: barX, y: 0, width: barW, height: h)
        
        if model.dayName == "Сегодня" {
            markerLayer.isHidden = false
            let markerSize: CGFloat = 8
            // Ставим маркер примерно в центр диапазона так как точную текущую температуру передать нельзя (ограничение моделей)
            let currentRatio = startRatio + (endRatio - startRatio) / 2
            let markerX = currentRatio * width - markerSize / 2
            markerLayer.frame = CGRect(x: markerX, y: -2, width: markerSize, height: markerSize)
        } else {
            markerLayer.isHidden = true
        }
    }
}
