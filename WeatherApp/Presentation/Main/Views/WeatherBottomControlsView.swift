import UIKit
import SnapKit

final class WeatherBottomControlsView: UIView {

    var onMapTap: (() -> Void)?
    var onPagerTap: (() -> Void)?
    var onListTap: (() -> Void)?

    private let margin: CGFloat = 20
    private let iconButtonSize: CGFloat = 54

    private lazy var mapButton = GlassControlButton(symbolName: "map")
    private lazy var listButton = GlassControlButton(symbolName: "list.bullet")
    private lazy var pagerButton = GlassPagerButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configurePager(isCurrentLocation: Bool) {
        pagerButton.configure(isCurrentLocation: isCurrentLocation)
    }

    private func setupUI() {
        backgroundColor = .clear

        [mapButton, pagerButton, listButton].forEach(addSubview)

        mapButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(margin)
            make.centerY.equalToSuperview()
            make.size.equalTo(iconButtonSize)
        }

        pagerButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(106)
            make.height.equalTo(iconButtonSize)
        }

        listButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(margin)
            make.centerY.equalToSuperview()
            make.size.equalTo(iconButtonSize)
        }

        mapButton.addTarget(self, action: #selector(handleMapTap), for: .touchUpInside)
        pagerButton.addTarget(self, action: #selector(handlePagerTap), for: .touchUpInside)
        listButton.addTarget(self, action: #selector(handleListTap), for: .touchUpInside)
    }

    @objc private func handleMapTap() {
        onMapTap?()
    }

    @objc private func handlePagerTap() {
        onPagerTap?()
    }

    @objc private func handleListTap() {
        onListTap?()
    }
}

private class GlassControlButton: UIButton {

    private let materialView = UIVisualEffectView(effect: nil)
    private let overlayView = UIView()
    private let cornerRadius: CGFloat = 23

    init(symbolName: String) {
        super.init(frame: .zero)
        setImage(UIImage(systemName: symbolName), for: .normal)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        materialView.frame = bounds
        overlayView.frame = bounds
    }

    private func setupUI() {
        backgroundColor = .clear
        tintColor = AppColors.textPrimary.withAlphaComponent(0.82)
        setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 25, weight: .regular),
            forImageIn: .normal
        )
        imageView?.contentMode = .scaleAspectFit
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.0 / UIScreen.main.scale
        layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        clipsToBounds = true

        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            glassEffect.tintColor = UIColor.black.withAlphaComponent(0.22)
            glassEffect.isInteractive = true
            materialView.effect = glassEffect
        } else {
            materialView.effect = UIBlurEffect(style: .systemThinMaterialDark)
        }

        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.16)
        overlayView.isUserInteractionEnabled = false
        materialView.isUserInteractionEnabled = false
        insertSubview(materialView, at: 0)
        insertSubview(overlayView, aboveSubview: materialView)
    }
}

private final class GlassPagerButton: GlassControlButton {

    private let locationImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "location.fill"))
        imageView.tintColor = AppColors.textPrimary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let firstDotView = UIView()
    private let secondDotView = UIView()

    init() {
        super.init(symbolName: "")
        setImage(nil, for: .normal)
        setupPagerUI()
        configure(isCurrentLocation: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(isCurrentLocation: Bool) {
        locationImageView.tintColor = AppColors.textPrimary.withAlphaComponent(isCurrentLocation ? 1.0 : 0.38)
        firstDotView.backgroundColor = AppColors.textPrimary.withAlphaComponent(isCurrentLocation ? 0.32 : 0.86)
        secondDotView.backgroundColor = AppColors.textPrimary.withAlphaComponent(0.32)
    }

    private func setupPagerUI() {
        layer.cornerRadius = 23

        [firstDotView, secondDotView].forEach { dotView in
            dotView.layer.cornerRadius = 4
        }

        let stackView = UIStackView(arrangedSubviews: [
            locationImageView,
            firstDotView,
            secondDotView
        ])
        stackView.axis = .horizontal
        stackView.spacing = 13
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        locationImageView.snp.makeConstraints { make in
            make.size.equalTo(18)
        }

        [firstDotView, secondDotView].forEach { dotView in
            dotView.snp.makeConstraints { make in
                make.size.equalTo(8)
            }
        }
    }
}
