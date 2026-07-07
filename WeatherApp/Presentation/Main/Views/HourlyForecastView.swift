import UIKit
import SnapKit

final class HourlyForecastView: UIView {

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white.withAlphaComponent(0.15)
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        return v
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 4
        sv.alignment = .center
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

        containerView.addSubview(scrollView)
        scrollView.addSubview(stackView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
        }

        // Критично: edges к contentLayoutGuide, height к frameLayoutGuide
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
                let sep = UIView()
                sep.backgroundColor = .white.withAlphaComponent(0.2)
                sep.snp.makeConstraints { $0.width.equalTo(1) }
                stackView.addArrangedSubview(sep)
            }
        }
    }
}

// MARK: - HourlyCell (private — видна только внутри этого файла)

private final class HourlyCell: UIView {

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()

    private let tempLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let stack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 6
        sv.alignment = .center
        return sv
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
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        iconView.image = UIImage(systemName: model.symbolName, withConfiguration: config)

        if model.isSpecial {
            tempLabel.text = "Закат"
            tempLabel.font = .systemFont(ofSize: 12)
        } else {
            tempLabel.text = model.temperature
            tempLabel.font = .systemFont(ofSize: 16, weight: .medium)
        }
    }
}
