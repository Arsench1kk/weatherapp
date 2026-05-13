import UIKit
import SnapKit

final class WeatherLoadingView: UIView {

    private let spinner: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.color = AppColors.textPrimary
        return activityIndicatorView
    }()

    override var isHidden: Bool {
        didSet {
            isHidden ? spinner.stopAnimating() : spinner.startAnimating()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(spinner)
        spinner.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil, !isHidden {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }
}
