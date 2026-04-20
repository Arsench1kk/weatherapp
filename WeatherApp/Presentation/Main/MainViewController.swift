import UIKit
import SnapKit

final class MainViewController: UIViewController {

    // MARK: - UI

    private let gradientView = UIView()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()

    private let contentView = UIView()

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.tintColor = .white.withAlphaComponent(0.8)
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return rc
    }()

    // Секции
    private let headerView  = WeatherHeaderView()
    private let summaryCard = WeatherSummaryCard()
    private let hourlyView  = HourlyForecastView()
    private let dailyView   = DailyForecastView()

    // Состояния
    private let loadingView = WeatherLoadingView()
    private let errorView   = WeatherErrorView()

    // MARK: - ViewModel

    private let viewModel: MainViewModel

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
        setupUI()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    // viewDidLayoutSubviews — вызывается каждый раз при изменении размеров
    // Именно здесь обновляем frame градиента
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }

    // MARK: - Setup

    private func setupUI() {
        // gradientView занимает весь экран
        view.addSubview(gradientView)
        gradientView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // scrollView внутри gradientView
        gradientView.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.refreshControl = refreshControl

        // contentView внутри scrollView
        // Ключевые constraints:
        // edges → contentLayoutGuide  (определяет scrollable area)
        // width → frameLayoutGuide    (фиксирует ширину = ширина экрана)
        // Без width → frameLayoutGuide контент будет бесконечно широким и скролл сломается
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        // Секции внутри contentView — вертикально цепочкой
        [headerView, summaryCard, hourlyView, dailyView].forEach {
            contentView.addSubview($0)
        }

        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        summaryCard.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        hourlyView.snp.makeConstraints { make in
            make.top.equalTo(summaryCard.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(120)
        }

        dailyView.snp.makeConstraints { make in
            make.top.equalTo(hourlyView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(100)  // отступ снизу для home indicator
        }

        // Состояния поверх gradientView
        [loadingView, errorView].forEach { gradientView.addSubview($0) }
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
        errorView.snp.makeConstraints   { $0.edges.equalToSuperview() }

        errorView.onRetry = { [weak self] in
            self?.viewModel.viewDidLoad()
        }
    }

    // MARK: - Gradient

    private func updateGradientFrame() {
        guard let gradientLayer = gradientView.layer.sublayers?.first(where: { $0 is CAGradientLayer }) else { return }
        gradientLayer.frame = gradientView.bounds
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
            updateUI(with: model)

        case .error(let message):
            loadingView.isHidden = true
            errorView.isHidden   = false
            errorView.configure(with: message)
            refreshControl.endRefreshing()
        }
    }

    private func updateUI(with model: MainWeatherUIModel) {
        let colors = GradientManager.colors(for: model.timeOfDay, isRaining: model.isRaining)
        gradientView.applyGradient(colors: colors)
        updateGradientFrame()

        headerView.configure(with: model)
        summaryCard.configure(with: model.conditionSummary)
        hourlyView.configure(with: model.hourlyForecast)
        dailyView.configure(with: model.dailyForecast)
    }

    // MARK: - Actions

    @objc private func handleRefresh() {
        viewModel.refresh()
    }
}
