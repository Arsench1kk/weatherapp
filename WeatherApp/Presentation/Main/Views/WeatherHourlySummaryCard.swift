import UIKit
import SnapKit

final class WeatherHourlySummaryCard: UIView {

    private let containerView = WeatherCardStyle.makeContainerView()

    private let summaryLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 16, weight: .regular), color: AppColors.textPrimary)
        label.numberOfLines = 0
        return label
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let hourlyStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
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

        let contentStack = UIStackView(arrangedSubviews: [
            summaryLabel,
            WeatherCardStyle.makeSeparator(),
            scrollView
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        containerView.addSubview(contentStack)

        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(WeatherCardStyle.contentInsets)
        }

        scrollView.snp.makeConstraints { $0.height.equalTo(105) }
        scrollView.addSubview(hourlyStackView)
        hourlyStackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.height.equalTo(scrollView.frameLayoutGuide)
            make.width.greaterThanOrEqualTo(scrollView.frameLayoutGuide)
        }
    }

    func configure(summary: String, items: [HourlyForecastUIModel]) {
        summaryLabel.text = summary

        hourlyStackView.arrangedSubviews.forEach { view in
            hourlyStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for item in items {
            let cell = WeatherHourlySummaryCell()
            cell.configure(with: item)
            hourlyStackView.addArrangedSubview(cell)
        }
    }
}

private final class WeatherHourlySummaryCell: UIView {

    private let timeLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 15, weight: .regular), color: AppColors.textPrimary, alignment: .center)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let temperatureLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 15, weight: .regular), color: AppColors.textPrimary, alignment: .center)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .center
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        [timeLabel, iconView, temperatureLabel].forEach { stackView.addArrangedSubview($0) }
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        iconView.snp.makeConstraints { $0.size.equalTo(24) }
        snp.makeConstraints { $0.width.greaterThanOrEqualTo(38) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with model: HourlyForecastUIModel) {
        timeLabel.text = model.time
        temperatureLabel.text = model.isSpecial ? "Закат" : model.temperature
        temperatureLabel.font = model.isSpecial
            ? UIFont.systemFont(ofSize: 11, weight: .regular)
            : UIFont.systemFont(ofSize: 12, weight: .regular)

        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        iconView.image = UIImage(systemName: model.symbolName, withConfiguration: config)?
            .withRenderingMode(.alwaysOriginal)
            .applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [
                AppColors.weatherSunIcon,
                AppColors.weatherCloudIcon,
                AppColors.weatherPrecipitationIcon
            ]))
    }
}
