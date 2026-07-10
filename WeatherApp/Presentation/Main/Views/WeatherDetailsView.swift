import UIKit
import SnapKit

final class WeatherDetailsView: UIView {

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()

    private let averageCard = WeatherAverageCard()
    private let feelsLikeCard = WeatherMetricCard(iconName: "thermometer", title: "ОЩУЩАЕТСЯ КАК")
    private let windCard = WeatherWindCard()
    private let uvCard = WeatherUVIndexCard()
    private let sunsetCard = WeatherMetricCard(iconName: "sunset.fill", title: "ЗАКАТ")
    private let humidityCard = WeatherMetricCard(iconName: "humidity.fill", title: "ВЛАЖНОСТЬ")
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
            detail: "По ощущениям теплее, чем на самом деле."
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
        let row = UIStackView(arrangedSubviews: [first, second])
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        return row
    }
}

private class WeatherBaseCard: UIView {

    let containerView = WeatherCardStyle.makeContainerView()
    let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
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

        contentStackView.addArrangedSubview(WeatherCardStyle.makeSectionTitle(iconName: iconName, title: title))
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(138) }
    }
}

private final class WeatherMetricCard: WeatherBaseCard {

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .medium)
        label.textColor = WeatherCardStyle.primaryTextColor
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    private let spacer = UIView()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = WeatherCardStyle.primaryTextColor
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
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .medium)
        label.textColor = WeatherCardStyle.primaryTextColor
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = WeatherCardStyle.primaryTextColor
        label.numberOfLines = 2
        return label
    }()

    private let todayLabel = WeatherSmallMetricLabel()
    private let averageLabel = WeatherSmallMetricLabel()

    init() {
        super.init(iconName: "chart.line.uptrend.xyaxis", title: "В СРЕДНЕМ")
        [valueLabel, descriptionLabel, todayLabel, averageLabel].forEach { contentStackView.addArrangedSubview($0) }
        contentStackView.setCustomSpacing(0, after: valueLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with model: MainWeatherUIModel) {
        valueLabel.text = "На 10°"
        descriptionLabel.text = "выше среднесуточного максимума"
        todayLabel.configure(title: "Сегодня", value: "Макс.: \(model.todayMaxTemperature)")
        averageLabel.configure(title: "В среднем", value: "Макс.: 1°")
    }
}

private final class WeatherWindCard: WeatherBaseCard {

    private let windRow = WeatherKeyValueRow()
    private let gustRow = WeatherKeyValueRow()
    private let directionRow = WeatherKeyValueRow()

    init() {
        super.init(iconName: "wind", title: "ВЕТЕР")
        contentStackView.addArrangedSubview(makeRowsStack())
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with model: MainWeatherUIModel) {
        windRow.configure(title: "Ветер", value: model.windSpeed)
        gustRow.configure(title: "Порывы ветра", value: model.windGust)
        directionRow.configure(title: "Направление", value: model.windDirection)
    }

    private func makeRowsStack() -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [
            windRow,
            WeatherCardStyle.makeSeparator(),
            gustRow,
            WeatherCardStyle.makeSeparator(),
            directionRow
        ])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .fill
        return stack
    }
}

private final class WeatherUVIndexCard: WeatherBaseCard {

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .medium)
        label.textColor = WeatherCardStyle.primaryTextColor
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = WeatherCardStyle.primaryTextColor
        return label
    }()

    private let uvBar = WeatherUVBarView()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = WeatherCardStyle.primaryTextColor
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
    }
}

private final class WeatherPressureCard: WeatherBaseCard {

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .medium)
        label.textColor = WeatherCardStyle.primaryTextColor
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    private let spacer = UIView()

    private let unitStack: UIStackView = {
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium))
        iconView.tintColor = WeatherCardStyle.primaryTextColor
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { $0.size.equalTo(18) }

        let label = UILabel()
        label.text = "гПа"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = WeatherCardStyle.primaryTextColor

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        return stack
    }()

    init() {
        super.init(iconName: "gauge.with.dots.needle.33percent", title: "ДАВЛЕНИЕ")
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
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = WeatherCardStyle.primaryTextColor
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = WeatherCardStyle.secondaryTextColor
        label.textAlignment = .right
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

private final class WeatherSmallMetricLabel: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = WeatherCardStyle.titleColor
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.textAlignment = .right
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
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
        view.backgroundColor = .white
        view.layer.cornerRadius = 2
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 2
        clipsToBounds = true
        addSubview(indicatorView)
        indicatorView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(4)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyGradient()
    }

    private func applyGradient() {
        layer.sublayers?
            .filter { $0 is CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }

        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.colors = [
            UIColor(red: 104 / 255, green: 213 / 255, blue: 72 / 255, alpha: 1).cgColor,
            UIColor(red: 236 / 255, green: 215 / 255, blue: 12 / 255, alpha: 1).cgColor,
            UIColor(red: 250 / 255, green: 160 / 255, blue: 46 / 255, alpha: 1).cgColor,
            UIColor(red: 251 / 255, green: 61 / 255, blue: 87 / 255, alpha: 1).cgColor,
            UIColor(red: 215 / 255, green: 59 / 255, blue: 222 / 255, alpha: 1).cgColor
        ]
        layer.insertSublayer(gradient, at: 0)
    }
}
