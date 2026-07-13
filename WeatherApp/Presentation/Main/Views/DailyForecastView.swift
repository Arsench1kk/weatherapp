import UIKit
import SnapKit

private enum DailyForecastLayout {
    static let horizontalInset: CGFloat = 20
    static let headerVerticalInset: CGFloat = 14
    static let rowVerticalInset: CGFloat = 11
    static let rowSpacing: CGFloat = 10
    static let dayWidth: CGFloat = 78
    static let iconSize: CGFloat = 26
    static let temperatureWidth: CGFloat = 36
    static let minimumBarWidth: CGFloat = 36
}

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
            let row = DailyForecastRow()
            let range = normalizer.range(for: item)
            row.configure(with: item, startRatio: range.start, endRatio: range.end)
            stackView.addArrangedSubview(row)

            if index < items.count - 1 {
                let sepWrapper = UIView()
                let sep = WeatherCardStyle.makeSeparator()
                sepWrapper.addSubview(sep)
                sep.snp.makeConstraints { make in
                    make.top.bottom.equalToSuperview()
                    make.leading.trailing.equalToSuperview().inset(DailyForecastLayout.horizontalInset)
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

    private let rangeBarView = DailyTemperatureRangeBarView()

    private let maxTempLabel: UILabel = {
        let l = AppTextStyle.label(style: UIFont.systemFont(ofSize: 18, weight: .regular), color: AppColors.textPrimary)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [
            dayLabel, iconView, minTempLabel, rangeBarView, maxTempLabel
        ])
        stack.axis = .horizontal
        stack.spacing = DailyForecastLayout.rowSpacing
        stack.alignment = .center
        addSubview(stack)

        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(
                top: DailyForecastLayout.rowVerticalInset,
                left: DailyForecastLayout.horizontalInset,
                bottom: DailyForecastLayout.rowVerticalInset,
                right: DailyForecastLayout.horizontalInset
            ))
        }

        rangeBarView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rangeBarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        dayLabel.snp.makeConstraints { $0.width.equalTo(DailyForecastLayout.dayWidth) }
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
        minTempLabel.text = "\(model.minTemp)°"
        maxTempLabel.text = "\(model.maxTemp)°"
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
        accessibilityLabel = "\(model.dayName), \(model.conditionDescription), минимум \(model.minTemp) градусов, максимум \(model.maxTemp) градусов."
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
        let end = (item.maxTemperatureValue - globalMin) / globalRange

        let clampedStart = CGFloat(min(max(start, 0), 1))
        let clampedEnd = CGFloat(min(max(end, 0), 1))

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
