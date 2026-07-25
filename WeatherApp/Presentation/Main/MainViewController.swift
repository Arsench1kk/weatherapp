import UIKit
import SnapKit

#if DEBUG_WEATHER_THEME_CONTROLS
private enum DebugTimeOverride: Int, CaseIterable {
    case automatic
    case morning
    case day
    case evening
    case night

    var title: String {
        switch self {
        case .automatic: return "Авто"
        case .morning: return "У"
        case .day: return "Д"
        case .evening: return "В"
        case .night: return "Н"
        }
    }

    var timeOfDay: TimeOfDay? {
        switch self {
        case .automatic: return nil
        case .morning: return .morning
        case .day: return .day
        case .evening: return .evening
        case .night: return .night
        }
    }
}
#endif

final class MainViewController: UIViewController {

    let locationSource: WeatherLocationSource

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let topContentOffset: CGFloat = 8
        static let bottomContentClearance: CGFloat = 104
        static let preferredHeaderHeight: CGFloat = 212
        static let minimumHeaderHeight: CGFloat = 176
    }

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()

    private let contentView = UIView()

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = AppColors.textSecondary
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return refreshControl
    }()

    // Секции
    private let headerView = WeatherHeaderView()
    private let hourlySummaryCard = WeatherHourlySummaryCard()
    private let dailyView = DailyForecastView()
    private let detailsView = WeatherDetailsView()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = WeatherCardStyle.sectionSpacing
        return stackView
    }()

    // Состояния
    private let loadingView = WeatherLoadingView()
    private let errorView   = WeatherErrorView()
    private let statusBannerLabel: UILabel = {
        let label = AppTextStyle.label(
            style: UIFont.systemFont(ofSize: 14, weight: .medium),
            color: AppColors.textPrimary,
            alignment: .center
        )
        label.numberOfLines = 0
        label.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        label.layer.cornerRadius = 18
        label.layer.cornerCurve = .continuous
        label.layer.borderWidth = 1.0 / UIScreen.main.scale
        label.layer.borderColor = UIColor.white.withAlphaComponent(0.24).cgColor
        label.clipsToBounds = true
        label.alpha = 0
        label.isHidden = true
        return label
    }()

    #if DEBUG_WEATHER_THEME_CONTROLS
    private lazy var debugTimeSegmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(
            items: DebugTimeOverride.allCases.map(\.title)
        )
        segmentedControl.selectedSegmentIndex = DebugTimeOverride.automatic.rawValue
        segmentedControl.addTarget(
            self,
            action: #selector(handleDebugTimeChanged),
            for: .valueChanged
        )
        return segmentedControl
    }()

    private lazy var debugRainSwitch: UISwitch = {
        let rainSwitch = UISwitch()
        rainSwitch.addTarget(
            self,
            action: #selector(handleDebugRainChanged),
            for: .valueChanged
        )
        return rainSwitch
    }()

    private lazy var debugControlsView: UIView = {
        let containerView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        containerView.layer.cornerRadius = 20
        containerView.layer.cornerCurve = .continuous
        containerView.clipsToBounds = true

        let rainLabel = AppTextStyle.label(
            style: UIFont.systemFont(ofSize: 13, weight: .semibold),
            color: AppColors.textPrimary
        )
        rainLabel.text = "Дождь"

        let rainStackView = UIStackView(arrangedSubviews: [rainLabel, debugRainSwitch])
        rainStackView.axis = .horizontal
        rainStackView.spacing = 8
        rainStackView.alignment = .center

        let controlsStackView = UIStackView(arrangedSubviews: [
            debugTimeSegmentedControl,
            rainStackView
        ])
        controlsStackView.axis = .horizontal
        controlsStackView.spacing = 10
        controlsStackView.alignment = .center

        containerView.contentView.addSubview(controlsStackView)
        controlsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10))
        }

        return containerView
    }()
    #endif

    // MARK: - ViewModel

    private let viewModel: MainViewModel
    
    // MARK: - State
    
    private var gradientApplied = false
    private var currentTimeOfDay: TimeOfDay = .current()
    private var currentIsRaining = false
    private var hasLoadedContent = false
    private var hasPlayedInitialSectionAnimation = false
    private var statusBannerHideWorkItem: DispatchWorkItem?
    #if DEBUG_WEATHER_THEME_CONTROLS
    private var latestLoadedModel: MainWeatherUIModel?
    private var debugTimeOverride: DebugTimeOverride = .automatic
    private var debugForcesRain = false
    #endif

    // MARK: - Init

    init(viewModel: MainViewModel, source: WeatherLocationSource) {
        self.viewModel = viewModel
        self.locationSource = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Удаляем любой фон
        view.backgroundColor = .clear
        
        setupNavigation()
        setupUI()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    func currentWeatherTheme() -> WeatherTheme {
        WeatherTheme(timeOfDay: currentTimeOfDay, isRaining: currentIsRaining)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !gradientApplied {
            GradientManager.shared.applyGradient(
                to: view.layer,
                timeOfDay: currentTimeOfDay,
                isRaining: currentIsRaining
            )
            gradientApplied = true
        } else {
            view.layer.sublayers?
                .first(where: { $0.name == GradientManager.gradientLayerName })?
                .frame = view.bounds
        }
    }

    // MARK: - Setup

    private func setupUI() {
        // scrollView
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        scrollView.refreshControl = refreshControl

        // contentView
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        contentView.addSubview(contentStackView)
        [headerView, hourlySummaryCard, dailyView, detailsView].forEach {
            contentStackView.addArrangedSubview($0)
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.topContentOffset)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.bottom.equalToSuperview().inset(Layout.bottomContentClearance)
        }

        headerView.snp.makeConstraints { make in
            make.height.equalTo(Layout.preferredHeaderHeight).priority(.high)
            make.height.greaterThanOrEqualTo(Layout.minimumHeaderHeight)
        }

        // Состояния поверх всего
        [loadingView, errorView].forEach { view.addSubview($0) }
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
        errorView.snp.makeConstraints   { $0.edges.equalToSuperview() }

        view.addSubview(statusBannerLabel)
        statusBannerLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        errorView.onRetry = { [weak self] in
            self?.viewModel.viewDidLoad()
        }

        #if DEBUG_WEATHER_THEME_CONTROLS
        setupDebugControls()
        #endif
    }

    private func setupNavigation() {
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.tintColor = AppColors.textPrimary
        navigationItem.rightBarButtonItem = nil
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] state in
            self?.apply(state: state)
        }
    }

    private func apply(state: MainScreenState) {
        switch state {
        case .loading:
            loadingView.isHidden = false
            errorView.isHidden   = true
            scrollView.isHidden  = true

        case .loaded(let model):
            let shouldAnimateInitialSections = !hasPlayedInitialSectionAnimation
            loadingView.isHidden = true
            errorView.isHidden   = true
            if shouldAnimateInitialSections {
                prepareInitialSectionAnimation()
            }
            scrollView.isHidden  = false
            hasLoadedContent = true
            #if DEBUG_WEATHER_THEME_CONTROLS
            latestLoadedModel = model
            #endif
            refreshControl.endRefreshing()

            let theme = effectiveTheme(for: model)
            applyWeatherTheme(timeOfDay: theme.timeOfDay, isRaining: theme.isRaining)
            
            updateUI(with: model)
            if shouldAnimateInitialSections {
                hasPlayedInitialSectionAnimation = true
                animateInitialSections()
            }

        case .error(let message, let preservesContent):
            loadingView.isHidden = true
            refreshControl.endRefreshing()

            if preservesContent, hasLoadedContent {
                errorView.isHidden = true
                scrollView.isHidden = false
                showTransientStatus(message)
            } else {
                errorView.isHidden = false
                scrollView.isHidden = true
                errorView.configure(with: message)
            }
        }
    }

    private func updateUI(with model: MainWeatherUIModel) {
        headerView.configure(with: model)
        hourlySummaryCard.configure(summary: model.conditionSummary, items: model.hourlyForecast)
        dailyView.configure(with: model.dailyForecast)
        detailsView.configure(with: model)
    }

    private func prepareInitialSectionAnimation() {
        contentStackView.arrangedSubviews.forEach { sectionView in
            sectionView.alpha = 0
            sectionView.transform = CGAffineTransform(translationX: 0, y: 26)
        }
    }

    private func animateInitialSections() {
        let sections = contentStackView.arrangedSubviews.reversed()
        let delayStep: TimeInterval = 0.08

        sections.enumerated().forEach { index, sectionView in
            UIView.animate(
                withDuration: 0.48,
                delay: TimeInterval(index) * delayStep,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.18,
                options: [.curveEaseOut, .allowUserInteraction]
            ) {
                sectionView.alpha = 1
                sectionView.transform = .identity
            } completion: { _ in
                sectionView.alpha = 1
                sectionView.transform = .identity
            }
        }
    }

    private func applyWeatherTheme(timeOfDay: TimeOfDay, isRaining: Bool) {
        updateGradientIfNeeded(timeOfDay: timeOfDay, isRaining: isRaining)
        WeatherCardStyle.applyTheme(
            to: contentView,
            timeOfDay: timeOfDay,
            isRaining: isRaining
        )
    }

    private func effectiveTheme(for model: MainWeatherUIModel) -> (timeOfDay: TimeOfDay, isRaining: Bool) {
        #if DEBUG_WEATHER_THEME_CONTROLS
        (
            debugTimeOverride.timeOfDay ?? model.timeOfDay,
            debugForcesRain || model.isRaining
        )
        #else
        (model.timeOfDay, model.isRaining)
        #endif
    }

    private func updateGradientIfNeeded(timeOfDay: TimeOfDay, isRaining: Bool) {
        guard timeOfDay != currentTimeOfDay || isRaining != currentIsRaining else { return }

        currentTimeOfDay = timeOfDay
        currentIsRaining = isRaining
        gradientApplied = false
        view.setNeedsLayout()
    }

    // MARK: - Actions

    @objc private func handleRefresh() {
        viewModel.refresh()
    }

    private func showTransientStatus(_ message: String) {
        statusBannerHideWorkItem?.cancel()
        statusBannerLabel.text = message
        statusBannerLabel.isHidden = false

        UIView.animate(withDuration: 0.22) {
            self.statusBannerLabel.alpha = 1
        }

        let hideWorkItem = DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: 0.22, animations: {
                self?.statusBannerLabel.alpha = 0
            }, completion: { _ in
                self?.statusBannerLabel.isHidden = true
            })
        }

        statusBannerHideWorkItem = hideWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: hideWorkItem)
    }

    #if DEBUG_WEATHER_THEME_CONTROLS
    private func setupDebugControls() {
        view.addSubview(debugControlsView)
        debugControlsView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
        }

        scrollView.contentInset.bottom += 64
        scrollView.verticalScrollIndicatorInsets.bottom += 64
    }

    @objc private func handleDebugTimeChanged() {
        let selectedIndex = debugTimeSegmentedControl.selectedSegmentIndex
        debugTimeOverride = DebugTimeOverride(rawValue: selectedIndex) ?? .automatic
        reapplyDebugThemeIfPossible()
    }

    @objc private func handleDebugRainChanged() {
        debugForcesRain = debugRainSwitch.isOn
        reapplyDebugThemeIfPossible()
    }

    private func reapplyDebugThemeIfPossible() {
        guard let latestLoadedModel else { return }
        let theme = effectiveTheme(for: latestLoadedModel)
        applyWeatherTheme(timeOfDay: theme.timeOfDay, isRaining: theme.isRaining)
    }
    #endif
}
