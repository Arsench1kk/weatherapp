import UIKit
import SnapKit

final class HourlyForecastView: UIView {

    private let containerView = WeatherCardStyle.makeContainerView()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
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

        containerView.addSubview(scrollView)
        scrollView.addSubview(stackView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(WeatherCardStyle.contentInsets)
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.height.equalTo(scrollView.frameLayoutGuide)
        }
    }

    func configure(with items: [HourlyForecastUIModel]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, item) in items.enumerated() {
            let cell = HourlyCell()
            cell.configure(with: item)
            stackView.addArrangedSubview(cell)

            if index < items.count - 1 {
                let separatorView = WeatherCardStyle.makeSeparator()
                separatorView.snp.makeConstraints { $0.width.equalTo(1) }
                stackView.addArrangedSubview(separatorView)
            }
        }
    }
}

// MARK: - HourlyCell

private final class HourlyCell: UIView {

    private let timeLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 15, weight: .regular), color: AppColors.textPrimary, alignment: .center)
        return label
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let tempLabel: UILabel = {
        let label = AppTextStyle.label(style: UIFont.systemFont(ofSize: 17, weight: .semibold), color: AppColors.textPrimary, alignment: .center)
        return label
    }()

    private let stack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.alignment = .center
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        [timeLabel, iconView, tempLabel].forEach { stack.addArrangedSubview($0) }
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14))
        }
        iconView.snp.makeConstraints { $0.size.equalTo(24) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with model: HourlyForecastUIModel) {
        timeLabel.text = model.time
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        iconView.image = UIImage(systemName: model.symbolName, withConfiguration: config)?
            .withRenderingMode(.alwaysOriginal)
            .applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [
                AppColors.weatherSunIcon,
                AppColors.weatherCloudIcon,
                AppColors.weatherPrecipitationIcon
            ]))

        if model.isSpecial {
            tempLabel.text = "Закат"
            tempLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        } else {
            tempLabel.text = model.temperature
            tempLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        }
    }
}
