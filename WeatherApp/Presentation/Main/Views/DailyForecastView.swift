import UIKit
import SnapKit

// MARK: - DailyForecastView (контейнер)

final class DailyForecastView: UIView {

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = WeatherCardStyle.backgroundColor
        v.layer.cornerRadius = WeatherCardStyle.cornerRadius
        v.clipsToBounds = true
        return v
    }()

    private let headerIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "calendar", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))
        iv.tintColor = WeatherCardStyle.titleColor
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let headerLabel: UILabel = {
        let l = UILabel()
        l.text = "ПРОГНОЗ НА 10 ДНЕЙ"
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = WeatherCardStyle.titleColor
        return l
    }()

    private lazy var headerStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [headerIconView, headerLabel])
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

        [headerStackView, stackView].forEach { containerView.addSubview($0) }

        headerIconView.snp.makeConstraints { $0.size.equalTo(16) }

        headerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalToSuperview().inset(16)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(12)
        }
    }

    func configure(with items: [DailyForecastUIModel]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, item) in items.enumerated() {
            let row = DailyForecastRow()
            row.configure(with: item)
            stackView.addArrangedSubview(row)

            if index < items.count - 1 {
                let sep = UIView()
                sep.backgroundColor = WeatherCardStyle.separatorColor
                sep.snp.makeConstraints { $0.height.equalTo(1) }
                stackView.addArrangedSubview(sep)
            }
        }
    }
}

// MARK: - DailyForecastRow (строка с температурной шкалой)

final class DailyForecastRow: UIView {

    private let dayLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .medium)
        l.textColor = WeatherCardStyle.primaryTextColor
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = WeatherCardStyle.primaryTextColor
        return iv
    }()

    private let minTempLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
        l.textColor = WeatherCardStyle.secondaryTextColor
        l.textAlignment = .right
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()

    private let barContainer = UIView()  // Здесь рисуется CAGradientLayer

    private let maxTempLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
        l.textColor = WeatherCardStyle.primaryTextColor
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()

    private var currentModel: DailyForecastUIModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [
            dayLabel, iconView, minTempLabel, barContainer, maxTempLabel
        ])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        addSubview(stack)

        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16))
        }

        dayLabel.snp.makeConstraints    { $0.width.equalTo(90) }
        iconView.snp.makeConstraints    { $0.size.equalTo(24) }
        minTempLabel.snp.makeConstraints { $0.width.equalTo(36) }
        maxTempLabel.snp.makeConstraints { $0.width.equalTo(36) }
        barContainer.snp.makeConstraints { $0.height.equalTo(4) }
    }

    func configure(with model: DailyForecastUIModel) {
        currentModel = model
        dayLabel.text    = model.dayName
        minTempLabel.text = "\(model.minTemp)°"
        maxTempLabel.text = "\(model.maxTemp)°"

        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconView.image = UIImage(systemName: model.symbolName, withConfiguration: config)

        setNeedsLayout()  // Просим пересчитать layout → вызовет layoutSubviews
    }

    // layoutSubviews вызывается ПОСЛЕ того как view получила реальный frame
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let model = currentModel else { return }
        drawTemperatureBar(model: model)
    }

    private func drawTemperatureBar(model: DailyForecastUIModel) {
        barContainer.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let width = barContainer.bounds.width
        guard width > 0 else { return }

        let globalRange = Double(model.globalMax - model.globalMin)
        guard globalRange > 0 else { return }

        let startRatio = CGFloat(model.minTemp - model.globalMin) / CGFloat(globalRange)
        let endRatio   = CGFloat(model.maxTemp - model.globalMin) / CGFloat(globalRange)

        let h: CGFloat = 4
        let r: CGFloat = 2

        // Серый фон (вся ширина)
        let bg = CALayer()
        bg.frame = CGRect(x: 0, y: 0, width: width, height: h)
        bg.backgroundColor = UIColor.black.withAlphaComponent(0.08).cgColor
        bg.cornerRadius = r
        barContainer.layer.addSublayer(bg)

        // Цветная полоска
        let barX = startRatio * width
        let barW = max((endRatio - startRatio) * width, 8)

        let bar = CALayer()
        bar.frame = CGRect(x: barX, y: 0, width: barW, height: h)
        bar.cornerRadius = r
        bar.backgroundColor = WeatherCardStyle.accentMint.cgColor
        barContainer.layer.addSublayer(bar)
    }
}
