import UIKit
import SnapKit

// MARK: - DailyForecastView (контейнер)

final class DailyForecastView: UIView {

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white.withAlphaComponent(0.15)
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        return v
    }()

    private let headerLabel: UILabel = {
        let l = UILabel()
        l.text = "☰ ПРОГНОЗ НА 10 ДНЕЙ"
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .white.withAlphaComponent(0.7)
        return l
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

        [headerLabel, stackView].forEach { containerView.addSubview($0) }

        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalToSuperview().inset(16)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
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
                sep.backgroundColor = .white.withAlphaComponent(0.15)
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
        l.textColor = .white
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()

    private let minTempLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
        l.textColor = .white.withAlphaComponent(0.6)
        l.textAlignment = .right
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()

    private let barContainer = UIView()  // Здесь рисуется CAGradientLayer

    private let maxTempLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
        l.textColor = .white
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
        barContainer.snp.makeConstraints { $0.height.equalTo(6) }
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

        let h: CGFloat = 6
        let r: CGFloat = 3

        // Серый фон (вся ширина)
        let bg = CALayer()
        bg.frame = CGRect(x: 0, y: 0, width: width, height: h)
        bg.backgroundColor = UIColor.white.withAlphaComponent(0.2).cgColor
        bg.cornerRadius = r
        barContainer.layer.addSublayer(bg)

        // Цветная полоска
        let barX = startRatio * width
        let barW = max((endRatio - startRatio) * width, 8)

        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: barX, y: 0, width: barW, height: h)
        gradient.cornerRadius = r
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)

        let cold = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1)
        let warm = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1)
        let mid  = UIColor(red: 0.6, green: 0.85, blue: 0.6, alpha: 1)
        let avg  = (startRatio + endRatio) / 2

        let (startColor, endColor): (UIColor, UIColor)
        if avg < 0.3 {
            (startColor, endColor) = (cold, cold.withAlphaComponent(0.8))
        } else if avg > 0.7 {
            (startColor, endColor) = (warm.withAlphaComponent(0.8), warm)
        } else {
            let t = (avg - 0.3) / 0.4
            startColor = blend(cold, mid,  t: t)
            endColor   = blend(mid,  warm, t: t)
        }

        gradient.colors = [startColor.cgColor, endColor.cgColor]
        barContainer.layer.addSublayer(gradient)
    }

    private func blend(_ a: UIColor, _ b: UIColor, t: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red:   r1 + (r2 - r1) * t,
            green: g1 + (g2 - g1) * t,
            blue:  b1 + (b2 - b1) * t,
            alpha: a1 + (a2 - a1) * t
        )
    }
}
