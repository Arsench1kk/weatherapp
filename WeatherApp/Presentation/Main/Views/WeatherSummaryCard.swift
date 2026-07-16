import UIKit
import SnapKit

final class WeatherSummaryCard: UIView {

    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColors.weatherCardBackground
        layer.cornerRadius = WeatherCardStyle.cornerRadius
        clipsToBounds = true
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with text: String) {
        label.text = text
    }
}
