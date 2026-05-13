import UIKit
import SnapKit

private enum DailyForecastLayout {
    static let horizontalInset: CGFloat = 16
    static let headerVerticalInset: CGFloat = 14
    static let rowVerticalInset: CGFloat = 11
    static let rowSpacing: CGFloat = 8
    static let dayWidth: CGFloat = 64
    static let minimumDayWidth: CGFloat = 48
    static let iconSize: CGFloat = 24
    static let temperatureWidth: CGFloat = 42
    static let minimumBarWidth: CGFloat = 28
}

final class DailyForecastView: UIView {

    private let containerView = WeatherCardStyle.makeContainerView()

    private let headerLabel = AppTextStyle.label(
        style: AppTextStyle.weatherCardTitle,
        color: WeatherCardStyle.titleColor
    )

    private lazy var headerStack: UIStackView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "calendar", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))?
            .withRenderingMode(.alwaysTemplate)
        imageView.tintColor = WeatherCardStyle.iconTintColor
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { $0.size.equalTo(14) }

        let stackView = UIStackView(arrangedSubviews: [imageView, headerLabel])
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        return stackView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        return stackView
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
            make.top.bottom.equalToSuperview().inset(DailyForecastLayout.headerVerticalInset)
            make.leading.trailing.equalToSuperview().inset(DailyForecastLayout.horizontalInset)
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

        let normalizer = DailyTemperatureRangeNormalizer(items: items)

        for (index, item) in items.enumerated() {
            let forecastRow = DailyForecastRow()
            let range = normalizer.range(for: item)
            forecastRow.configure(with: item, startRatio: range.start, endRatio: range.end)
            stackView.addArrangedSubview(forecastRow)

            if index < items.count - 1 {
                let separatorWrapperView = UIView()
                let separatorView = WeatherCardStyle.makeSeparator()
                separatorWrapperView.addSubview(separatorView)
                separatorView.snp.makeConstraints { make in
                    make.top.bottom.equalToSuperview()
                    make.leading.trailing.equalToSuperview().inset(DailyForecastLayout.horizontalInset)
                }
                stackView.addArrangedSubview(separatorWrapperView)
                separatorWrapperView.snp.makeConstraints { $0.height.equalTo(1.0 / UIScreen.main.scale) }
            }
        }
    }
}

// MARK: - Row

private final class DailyForecastRow: UIView {

    private let dayLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 18, weight: .regular), color: AppColors.textPrimary)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.9
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let minTempLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 18, weight: .regular), color: WeatherCardStyle.secondaryTextColor)
        label.textAlignment = .right
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.78
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let rangeBarView = DailyTemperatureRangeBarView()

    private let maxTempLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 18, weight: .regular), color: AppColors.textPrimary)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.78
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [
            dayLabel, iconView, minTempLabel, rangeBarView, maxTempLabel
        ])
        stackView.axis = .horizontal
        stackView.spacing = DailyForecastLayout.rowSpacing
        stackView.alignment = .center
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(
                top: DailyForecastLayout.rowVerticalInset,
                left: DailyForecastLayout.horizontalInset,
                bottom: DailyForecastLayout.rowVerticalInset,
                right: DailyForecastLayout.horizontalInset
            ))
        }

        rangeBarView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rangeBarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        dayLabel.snp.makeConstraints { make in
            make.width.equalTo(DailyForecastLayout.dayWidth).priority(.high)
            make.width.greaterThanOrEqualTo(DailyForecastLayout.minimumDayWidth)
        }
        iconView.snp.makeConstraints { $0.size.equalTo(DailyForecastLayout.iconSize) }
        minTempLabel.snp.makeConstraints { $0.width.equalTo(DailyForecastLayout.temperatureWidth) }
        maxTempLabel.snp.makeConstraints { $0.width.equalTo(DailyForecastLayout.temperatureWidth) }
        rangeBarView.snp.makeConstraints {
            $0.height.equalTo(DailyTemperatureRangeBarView.preferredHeight)
            $0.width.greaterThanOrEqualTo(DailyForecastLayout.minimumBarWidth)
        }
    }

    func configure(with model: DailyForecastUIModel, startRatio: CGFloat, endRatio: CGFloat) {
        dayLabel.text    = model.dayName
        minTempLabel.text = model.minTemperatureText
        maxTempLabel.text = model.maxTemperatureText
        rangeBarView.configure(startRatio: startRatio, endRatio: endRatio)

        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        iconView.image = UIImage(systemName: model.symbolName, withConfiguration: config)?
            .withRenderingMode(.alwaysOriginal)
            .applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [
                AppColors.weatherSunIcon,
                AppColors.weatherCloudIcon,
                AppColors.weatherPrecipitationIcon
            ]))

        isAccessibilityElement = true
        accessibilityLabel = "\(model.dayName), \(model.conditionDescription), минимум \(model.minTemperatureText), максимум \(model.maxTemperatureText)."
    }
}

private struct DailyTemperatureRangeNormalizer {
    private let globalMin: Double
    private let globalRange: Double
    private let isFlatRange: Bool

    init(items: [DailyForecastUIModel]) {
        let minValue = items.map(\.minTemperatureValue).min() ?? 0
        let maxValue = items.map(\.maxTemperatureValue).max() ?? minValue
        globalMin = minValue
        isFlatRange = maxValue == minValue
        globalRange = max(maxValue - minValue, 1)
    }

    func range(for item: DailyForecastUIModel) -> (start: CGFloat, end: CGFloat) {
        if isFlatRange {
            return (0.5, 0.5)
        }

        let start = (item.minTemperatureValue - globalMin) / globalRange
        let endRatio = (item.maxTemperatureValue - globalMin) / globalRange

        let clampedStart = CGFloat(min(max(start, 0), 1))
        let clampedEnd = CGFloat(min(max(endRatio, 0), 1))

        if clampedEnd > clampedStart {
            return (clampedStart, clampedEnd)
        }

        let center = min(max((clampedStart + clampedEnd) / 2, 0), 1)
        return (center, center)
    }
}

private final class DailyTemperatureRangeBarView: UIView {
    static let preferredHeight: CGFloat = 6

    private let minimumActiveWidth: CGFloat = 7
    private var startRatio: CGFloat = 0
    private var endRatio: CGFloat = 0

    private let trackLayer = CALayer()
    private let activeLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        layer.addSublayer(trackLayer)
        layer.addSublayer(activeLayer)
        activeLayer.startPoint = CGPoint(x: 0, y: 0.5)
        activeLayer.endPoint = CGPoint(x: 1, y: 0.5)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(startRatio: CGFloat, endRatio: CGFloat) {
        self.startRatio = min(max(startRatio, 0), 1)
        self.endRatio = min(max(endRatio, 0), 1)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let barHeight = min(Self.preferredHeight, bounds.height)
        let y = (bounds.height - barHeight) / 2
        let trackFrame = CGRect(x: 0, y: y, width: bounds.width, height: barHeight)

        trackLayer.frame = trackFrame
        trackLayer.cornerRadius = barHeight / 2
        trackLayer.backgroundColor = AppColors.weatherTemperatureBarTrack.cgColor

        activeLayer.colors = [
            AppColors.weatherTemperatureBarStart.cgColor,
            AppColors.weatherTemperatureBarEnd.cgColor
        ]
        activeLayer.cornerRadius = barHeight / 2
        activeLayer.masksToBounds = true
        activeLayer.frame = activeFrame(in: trackFrame)
    }

    private func activeFrame(in trackFrame: CGRect) -> CGRect {
        guard trackFrame.width > 0 else { return .zero }

        let orderedStart = min(startRatio, endRatio)
        let orderedEnd = max(startRatio, endRatio)
        let rawX = orderedStart * trackFrame.width
        let rawWidth = (orderedEnd - orderedStart) * trackFrame.width
        let width = min(max(rawWidth, minimumActiveWidth), trackFrame.width)
        let centeredFallbackX = rawX - (width - rawWidth) / 2
        let x = min(max(centeredFallbackX, 0), trackFrame.width - width)

        return CGRect(x: trackFrame.minX + x, y: trackFrame.minY, width: width, height: trackFrame.height)
    }
}
