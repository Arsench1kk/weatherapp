import UIKit
import SnapKit

final class WeatherBottomControlsView: UIView {

    var onMapTap: (() -> Void)?
    var onPagerTap: (() -> Void)?
    var onListTap: (() -> Void)?

    private let margin: CGFloat = 18
    private let iconButtonSize: CGFloat = 44

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

    func configurePager(currentPage: Int, totalPages: Int) {
        pagerButton.configure(currentPage: currentPage, totalPages: totalPages)
    }

    func setMapEnabled(_ isEnabled: Bool) {
        mapButton.isEnabled = isEnabled
        mapButton.alpha = isEnabled ? 1 : 0.34
        mapButton.accessibilityTraits = isEnabled ? [.button] : [.button, .notEnabled]
        mapButton.accessibilityValue = isEnabled ? nil : "Недоступно"
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
            make.leading.greaterThanOrEqualTo(mapButton.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(listButton.snp.leading).offset(-10)
            make.width.greaterThanOrEqualTo(64)
            make.width.lessThanOrEqualTo(180)
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

        mapButton.accessibilityLabel = "Карта"
        mapButton.accessibilityHint = "Открывает карту погоды"
        pagerButton.accessibilityLabel = "Сохранённые города"
        pagerButton.accessibilityHint = "Показывает текущий город в списке"
        listButton.accessibilityLabel = "Список городов"
        listButton.accessibilityHint = "Открывает список сохранённых городов"
    }

    @objc private func handleMapTap() {
        AppHaptics.lightImpact()
        onMapTap?()
    }

    @objc private func handlePagerTap() {
        AppHaptics.lightImpact()
        onPagerTap?()
    }

    @objc private func handleListTap() {
        AppHaptics.lightImpact()
        onListTap?()
    }
}

private class GlassControlButton: UIButton {

    private let materialView = UIVisualEffectView(effect: nil)
    private let overlayView = UIView()
    private let cornerRadius: CGFloat = 22

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
        tintColor = AppColors.textPrimary.withAlphaComponent(0.72)
        setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 22, weight: .regular),
            forImageIn: .normal
        )
        imageView?.contentMode = .scaleAspectFit
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.0 / UIScreen.main.scale
        layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        clipsToBounds = true

        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            glassEffect.tintColor = UIColor.black.withAlphaComponent(0.16)
            glassEffect.isInteractive = true
            materialView.effect = glassEffect
        } else {
            materialView.effect = UIBlurEffect(style: .systemThinMaterialDark)
        }

        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.10)
        overlayView.isUserInteractionEnabled = false
        materialView.isUserInteractionEnabled = false
        insertSubview(materialView, at: 0)
        insertSubview(overlayView, aboveSubview: materialView)
        isAccessibilityElement = true
    }
}

private final class GlassPagerButton: GlassControlButton {

    private enum Metrics {
        static let horizontalInset: CGFloat = 13
        static let itemSpacing: CGFloat = 12
        static let locationSize: CGFloat = 17
        static let dotSize: CGFloat = 8
        static let height: CGFloat = 44
        static let maximumWidth: CGFloat = 180
    }

    private let locationImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "location.fill"))
        imageView.tintColor = AppColors.textPrimary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let indicatorStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Metrics.itemSpacing
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false
        return stackView
    }()
    private let indicatorScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isScrollEnabled = false
        scrollView.isUserInteractionEnabled = false
        scrollView.clipsToBounds = true
        return scrollView
    }()
    private var dotViews: [UIView] = []
    private var totalPages = 1
    private var currentPage = 0

    init() {
        super.init(symbolName: "")
        setImage(nil, for: .normal)
        setupPagerUI()
        configure(currentPage: 0, totalPages: 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(currentPage: Int, totalPages: Int) {
        let safeTotalPages = max(totalPages, 1)
        let safeCurrentPage = min(max(currentPage, 0), safeTotalPages - 1)

        self.totalPages = safeTotalPages
        self.currentPage = safeCurrentPage

        rebuildDotsIfNeeded(savedCityCount: safeTotalPages - 1)
        applyActiveIndicator()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        accessibilityValue = makeAccessibilityValue(currentPage: safeCurrentPage, totalPages: safeTotalPages)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: min(indicatorContentWidth + Metrics.horizontalInset * 2, Metrics.maximumWidth), height: Metrics.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateScrollInsets()
        scrollActiveIndicatorIntoView()
    }

    private func setupPagerUI() {
        layer.cornerRadius = 22
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        indicatorStackView.addArrangedSubview(locationImageView)
        addSubview(indicatorScrollView)
        indicatorScrollView.addSubview(indicatorStackView)

        indicatorScrollView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Metrics.horizontalInset)
            make.height.equalTo(max(Metrics.locationSize, Metrics.dotSize))
        }

        indicatorStackView.snp.makeConstraints { make in
            make.edges.equalTo(indicatorScrollView.contentLayoutGuide)
            make.height.equalTo(indicatorScrollView.frameLayoutGuide)
        }

        locationImageView.snp.makeConstraints { make in
            make.size.equalTo(Metrics.locationSize)
        }
        locationImageView.isAccessibilityElement = false
        indicatorScrollView.isAccessibilityElement = false
        indicatorStackView.isAccessibilityElement = false
    }

    private func rebuildDotsIfNeeded(savedCityCount: Int) {
        guard dotViews.count != savedCityCount else { return }

        dotViews.forEach { dotView in
            indicatorStackView.removeArrangedSubview(dotView)
            dotView.removeFromSuperview()
        }

        dotViews = (0..<savedCityCount).map { _ in
            let dotView = UIView()
            dotView.layer.cornerRadius = Metrics.dotSize / 2
            dotView.isAccessibilityElement = false
            dotView.snp.makeConstraints { make in
                make.size.equalTo(Metrics.dotSize)
            }
            indicatorStackView.addArrangedSubview(dotView)
            return dotView
        }
    }

    private func applyActiveIndicator() {
        locationImageView.tintColor = AppColors.textPrimary.withAlphaComponent(currentPage == 0 ? 0.78 : 0.34)

        for (index, dotView) in dotViews.enumerated() {
            let pageIndex = index + 1
            dotView.backgroundColor = AppColors.textPrimary.withAlphaComponent(pageIndex == currentPage ? 0.74 : 0.30)
        }
    }

    private var indicatorContentWidth: CGFloat {
        let savedCityCount = max(totalPages - 1, 0)
        let itemCount = savedCityCount + 1

        return Metrics.locationSize
            + CGFloat(savedCityCount) * Metrics.dotSize
            + CGFloat(max(itemCount - 1, 0)) * Metrics.itemSpacing
    }

    private func updateScrollInsets() {
        let availableWidth = indicatorScrollView.bounds.width
        let horizontalInset = max((availableWidth - indicatorContentWidth) / 2, 0)
        indicatorScrollView.contentInset = UIEdgeInsets(
            top: 0,
            left: horizontalInset,
            bottom: 0,
            right: horizontalInset
        )
    }

    private func scrollActiveIndicatorIntoView() {
        guard indicatorScrollView.bounds.width > 0 else { return }
        let activeView = currentPage == 0 ? locationImageView : dotViews[safe: currentPage - 1]
        guard let activeView else { return }
        let targetFrame = activeView.convert(activeView.bounds, to: indicatorScrollView)
        indicatorScrollView.scrollRectToVisible(targetFrame.insetBy(dx: -Metrics.itemSpacing, dy: 0), animated: false)
    }

    private func makeAccessibilityValue(currentPage: Int, totalPages: Int) -> String {
        let pageDescription = "\(currentPage + 1) из \(totalPages)"
        if currentPage == 0 {
            return "Текущее местоположение, \(pageDescription)"
        }
        return "Сохранённый город \(currentPage), \(pageDescription)"
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
