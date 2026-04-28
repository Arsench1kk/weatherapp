import UIKit
import SnapKit

final class MainViewController: UIViewController {

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()

    private let contentView = UIView()

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.tintColor = AppColors.textSecondary
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return rc
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

    // MARK: - ViewModel

    private let viewModel: MainViewModel
    
    // MARK: - State
    
    private var gradientApplied = false
    private var currentTimeOfDay: TimeOfDay = .current()
    private var currentIsRaining = false

    // MARK: - Init

    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
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
        
        setupUI()
        bindViewModel()
        viewModel.viewDidLoad()
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
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
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
            make.top.equalToSuperview().offset(116)
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().inset(48)
        }

        headerView.snp.makeConstraints { make in
            make.height.equalTo(259)
        }

        // Состояния поверх всего
        [loadingView, errorView].forEach { view.addSubview($0) }
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
        errorView.snp.makeConstraints   { $0.edges.equalToSuperview() }

        errorView.onRetry = { [weak self] in
            self?.viewModel.viewDidLoad()
        }
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
            loadingView.isHidden = true
            errorView.isHidden   = true
            scrollView.isHidden  = false
            refreshControl.endRefreshing()
            
            updateGradientIfNeeded(timeOfDay: model.timeOfDay, isRaining: model.isRaining)
            
            updateUI(with: model)

        case .error(let message):
            loadingView.isHidden = true
            errorView.isHidden   = false
            scrollView.isHidden  = true
            errorView.configure(with: message)
            refreshControl.endRefreshing()
        }
    }

    private func updateUI(with model: MainWeatherUIModel) {
        headerView.configure(with: model)
        hourlySummaryCard.configure(summary: model.conditionSummary, items: model.hourlyForecast)
        dailyView.configure(with: model.dailyForecast)
        detailsView.configure(with: model)
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
}
