import UIKit
import SnapKit

final class WeatherDetailsView: UIView {

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = WeatherCardStyle.interItemSpacing
        return stackView
    }()

    private let averageCard = WeatherAverageCard()
    private let feelsLikeCard = WeatherMetricCard(iconName: "thermometer", title: "ОЩУЩАЕТСЯ КАК")
    private let windCard = WeatherWindCard()
    private let uvCard = WeatherUVIndexCard()
    private let sunsetCard = WeatherMetricCard(iconName: "sunset.fill", title: "ЗАКАТ")
    private let humidityCard = WeatherMetricCard(iconName: "drop.fill", title: "ВЛАЖНОСТЬ")
    private let pressureCard = WeatherPressureCard()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }

        stackView.addArrangedSubview(makeRow(averageCard, feelsLikeCard))
        stackView.addArrangedSubview(windCard)
        stackView.addArrangedSubview(makeRow(uvCard, sunsetCard))
        stackView.addArrangedSubview(makeRow(humidityCard, pressureCard))
    }

    func configure(with model: MainWeatherUIModel) {
        averageCard.configure(with: model)
        feelsLikeCard.configure(
            value: model.feelsLike,
            detail: model.feelsLikeDetail
        )
        windCard.configure(with: model)
        uvCard.configure(value: model.uvIndex, description: model.uvDescription)
        sunsetCard.configure(
            value: model.sunset,
            detail: "Восход в \(model.sunrise)."
        )
        humidityCard.configure(
            value: model.humidity,
            detail: "Точка росы сейчас: \(model.dewPoint)."
        )
        pressureCard.configure(value: model.pressure)
    }

    private func makeRow(_ first: UIView, _ second: UIView) -> UIStackView {
        let rowStackView = UIStackView(arrangedSubviews: [first, second])
        rowStackView.axis = .horizontal
        rowStackView.spacing = WeatherCardStyle.interItemSpacing
        rowStackView.distribution = .fillEqually
        first.snp.makeConstraints { make in
            make.height.equalTo(first.snp.width).priority(.high)
            make.height.greaterThanOrEqualTo(150)
        }
        second.snp.makeConstraints { make in
            make.height.equalTo(second.snp.width).priority(.high)
            make.height.greaterThanOrEqualTo(150)
        }
        return rowStackView
    }
}

private class WeatherBaseCard: UIView {

    let containerView = WeatherCardStyle.makeContainerView()
    let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        return stackView
    }()

    init(iconName: String, title: String) {
        super.init(frame: .zero)
        setupUI(iconName: iconName, title: title)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI(iconName: String, title: String) {
        addSubview(containerView)
        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }

        containerView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(WeatherCardStyle.contentInsets)
        }

        contentStackView.addArrangedSubview(makeSectionTitle(iconName: iconName, title: title))
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(150) }
    }
    
    private func makeSectionTitle(iconName: String, title: String) -> UIView {
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: iconName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))?
            .withRenderingMode(.alwaysTemplate)
        iconView.tintColor = WeatherCardStyle.iconTintColor
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { $0.size.equalTo(14) }

        let label = AppTextStyle.label(style: AppTextStyle.weatherCardTitle, color: WeatherCardStyle.titleColor)
        label.text = title
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.82
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let titleStackView = UIStackView(arrangedSubviews: [iconView, label])
        titleStackView.axis = .horizontal
        titleStackView.spacing = 6
        titleStackView.alignment = .center
        return titleStackView
    }
}

private final class WeatherMetricCard: WeatherBaseCard {

    private let valueLabel: UILabel = {
        let label = AppTextStyle.label(style: AppTextStyle.weatherMetricValue, color: AppColors.textPrimary)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    private let spacer = UIView()

    private let detailLabel: UILabel = {
        let label = AppTextStyle.label(style: AppTextStyle.weatherCardBody, color: AppColors.textPrimary)
        label.numberOfLines = 0
        return label
    }()

    override init(iconName: String, title: String) {
        super.init(iconName: iconName, title: title)
        contentStackView.addArrangedSubview(valueLabel)
        contentStackView.addArrangedSubview(spacer)
        contentStackView.addArrangedSubview(detailLabel)
        contentStackView.setCustomSpacing(2, after: valueLabel)
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(value: String, detail: String) {
        valueLabel.text = value
        detailLabel.text = detail
    }
}

private final class WeatherAverageCard: WeatherBaseCard {

    private let valueLabel: UILabel = {
        let label = AppTextStyle.label(style: AppTextStyle.weatherMetricValue, color: AppColors.textPrimary)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = AppTextStyle.label(style: AppTextStyle.weatherCardBody, color: AppColors.textPrimary)
        label.numberOfLines = 2
        return label
    }()

    private let spacer = UIView()
    private let todayLabel = WeatherSmallMetricLabel()
    private let averageLabel = WeatherSmallMetricLabel()

    init() {
        super.init(iconName: "chart.line.uptrend.xyaxis", title: "В СРЕДНЕМ")
        [valueLabel, descriptionLabel, spacer, todayLabel, averageLabel].forEach { contentStackView.addArrangedSubview($0) }
        contentStackView.setCustomSpacing(0, after: valueLabel)
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with model: MainWeatherUIModel) {
        valueLabel.text = model.todayMaxTemperature
        descriptionLabel.text = "Сегодняшний максимум"
        todayLabel.configure(title: "Сегодня", value: "Макс.: \(model.todayMaxTemperature)")
        // TODO: Replace this row with average deviation when the API/UI model exposes that value.
        averageLabel.configure(title: "Ощущается", value: model.feelsLike)
    }
}

private final class WeatherWindCard: WeatherBaseCard {

    private let windRow = WeatherKeyValueRow()
    private let gustRow = WeatherKeyValueRow()
    private let directionRow = WeatherKeyValueRow()

    init() {
        super.init(iconName: "wind", title: "ВЕТЕР")
        contentStackView.addArrangedSubview(makeRowsStack())
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(178)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with model: MainWeatherUIModel) {
        windRow.configure(title: "Ветер", value: model.windSpeed)
        gustRow.configure(title: "Порывы ветра", value: model.windGust)
        directionRow.configure(title: "Направление", value: model.windDirection)
    }

    private func makeRowsStack() -> UIStackView {
        let rowsStackView = UIStackView(arrangedSubviews: [
            windRow,
            makePaddedSeparator(),
            gustRow,
            makePaddedSeparator(),
            directionRow
        ])
        rowsStackView.axis = .vertical
        rowsStackView.spacing = 10
        rowsStackView.alignment = .fill
        return rowsStackView
    }
    
    private func makePaddedSeparator() -> UIView {
        let separatorWrapperView = UIView()
        let separatorView = WeatherCardStyle.makeSeparator()
        separatorWrapperView.addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
        separatorWrapperView.snp.makeConstraints { $0.height.equalTo(1.0 / UIScreen.main.scale) }
        return separatorWrapperView
    }
}

private final class WeatherUVIndexCard: WeatherBaseCard {

    private let valueLabel: UILabel = {
        let label = AppTextStyle.label(style: AppTextStyle.weatherMetricValue, color: AppColors.textPrimary)
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 15, weight: .regular), color: AppColors.textPrimary)
        return label
    }()

    private let uvBar = WeatherUVBarView()

    private let detailLabel: UILabel = {
        let label = AppTextStyle.label(style: AppTextStyle.weatherCardBody, color: AppColors.textPrimary)
        label.numberOfLines = 0
        label.text = "Останется низким до конца дня."
        return label
    }()

    init() {
        super.init(iconName: "sun.max.fill", title: "УФ-ИНДЕКС")
        [valueLabel, descriptionLabel, uvBar, detailLabel].forEach { contentStackView.addArrangedSubview($0) }
        uvBar.snp.makeConstraints { make in
            make.height.equalTo(4)
            make.width.equalToSuperview()
        }
        contentStackView.setCustomSpacing(0, after: valueLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(value: String, description: String) {
        valueLabel.text = value
        descriptionLabel.text = description
        let uvIndex = Double(value) ?? 0
        detailLabel.text = makeDetailText(for: uvIndex)
        uvBar.configure(index: uvIndex)
    }

    private func makeDetailText(for value: Double) -> String {
        switch value {
        case 0..<3:
            return "Останется низким до конца дня."
        case 3..<6:
            return "Используйте солнцезащитный крем."
        default:
            return "Избегайте длительного пребывания на солнце."
        }
    }
}

private final class WeatherPressureCard: WeatherBaseCard {

    private let valueLabel: UILabel = {
        let label = AppTextStyle.label(style: AppTextStyle.weatherMetricValue, color: AppColors.textPrimary)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    private let spacer = UIView()

    private let unitStack: UIStackView = {
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium))?
            .withRenderingMode(.alwaysTemplate)
        iconView.tintColor = WeatherCardStyle.iconTintColor
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { $0.size.equalTo(14) }

        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 15, weight: .regular), color: WeatherCardStyle.secondaryTextColor)
        label.text = "гПа"

        let unitStackView = UIStackView(arrangedSubviews: [iconView, label])
        unitStackView.axis = .horizontal
        unitStackView.spacing = 5
        unitStackView.alignment = .center
        return unitStackView
    }()

    init() {
        super.init(iconName: "gauge", title: "ДАВЛЕНИЕ")
        contentStackView.addArrangedSubview(valueLabel)
        contentStackView.addArrangedSubview(spacer)
        contentStackView.addArrangedSubview(unitStack)
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(value: String) {
        valueLabel.text = value
    }
}

private final class WeatherKeyValueRow: UIView {

    private let titleLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 16, weight: .regular), color: AppColors.textPrimary)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let valueLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 16, weight: .regular), color: WeatherCardStyle.secondaryTextColor, alignment: .right)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let spacer = UIView()
        let stackView = UIStackView(arrangedSubviews: [titleLabel, spacer, valueLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
        snp.makeConstraints { $0.height.equalTo(24) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

private final class WeatherSmallMetricLabel: UIView {

    private let titleLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 12, weight: .regular), color: WeatherCardStyle.secondaryTextColor)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let valueLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 13, weight: .regular), color: AppColors.textPrimary, alignment: .right)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let spacer = UIView()
        let stackView = UIStackView(arrangedSubviews: [titleLabel, spacer, valueLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
        snp.makeConstraints { $0.height.equalTo(18) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

private final class WeatherUVBarView: UIView {

    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.weatherTemperatureMarker
        view.layer.cornerRadius = 2
        return view
    }()

    private var uvIndex: Double = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 2
        clipsToBounds = true
        addSubview(indicatorView)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyGradient()
        layoutIndicator()
    }

    func configure(index: Double) {
        uvIndex = max(0, min(index, 11))
        setNeedsLayout()
    }

    private func applyGradient() {
        layer.sublayers?
            .filter { $0 is CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }

        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.colors = AppColors.weatherUVGradientColors.map { $0.cgColor }
        layer.insertSublayer(gradient, at: 0)
    }

    private func layoutIndicator() {
        let indicatorWidth: CGFloat = 4
        let availableWidth = max(bounds.width - indicatorWidth, 0)
        let x = availableWidth * CGFloat(uvIndex / 11)
        indicatorView.frame = CGRect(x: x, y: 0, width: indicatorWidth, height: bounds.height)
    }
}
