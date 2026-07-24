import UIKit
import SnapKit

final class WeatherPagerViewController: UIViewController {

    typealias MainViewControllerFactory = (WeatherLocationSource) -> MainViewController
    typealias CitySearchViewControllerFactory = (
        WeatherTheme,
        @escaping (CitySelection) -> Void
    ) -> CitySearchViewController

    private let savedCitiesStore: SavedCitiesStoreProtocol
    private let makeMainViewController: MainViewControllerFactory
    private let makeCitySearchViewController: CitySearchViewControllerFactory

    private let pageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )
    private let bottomControlsView = WeatherBottomControlsView()
    private let citySearchTransitioningDelegate = WeatherCityListTransitioningDelegate()

    private var sources: [WeatherLocationSource] = []
    private var pageCache: [String: MainViewController] = [:]
    private var activePageIndex = 0
    #if DEBUG
    private var debugScript: DebugPagerScript?
    private var debugScriptTask: Task<Void, Never>?
    #endif

    init(
        savedCitiesStore: SavedCitiesStoreProtocol,
        makeMainViewController: @escaping MainViewControllerFactory,
        makeCitySearchViewController: @escaping CitySearchViewControllerFactory
    ) {
        self.savedCitiesStore = savedCitiesStore
        self.makeMainViewController = makeMainViewController
        self.makeCitySearchViewController = makeCitySearchViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        #if DEBUG
        debugScriptTask?.cancel()
        #endif
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override var childForStatusBarStyle: UIViewController? {
        currentMainViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        setupPageViewController()
        setupBottomControls()
        setupSavedCitiesObserver()
        reloadSources(selecting: initialSource(), animated: false)
        #if DEBUG
        runDebugScriptIfNeeded()
        #endif
        AppHaptics.prepareLightImpact()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        reloadSources(selecting: activeSource, animated: false)
    }

    private var currentMainViewController: MainViewController? {
        pageViewController.viewControllers?.first as? MainViewController
    }

    private var activeSource: WeatherLocationSource {
        guard sources.indices.contains(activePageIndex) else {
            return .currentLocation
        }

        return sources[activePageIndex]
    }

    private func initialSource() -> WeatherLocationSource {
        #if DEBUG
        if let source = debugScript?.initialSource(from: savedCitiesStore.loadCities()) {
            return source
        }
        #endif

        return .currentLocation
    }

    private func setupPageViewController() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        pageViewController.didMove(toParent: self)

        pageViewController.dataSource = self
        pageViewController.delegate = self
    }

    private func setupBottomControls() {
        view.addSubview(bottomControlsView)
        bottomControlsView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(8)
            make.height.equalTo(44)
        }

        bottomControlsView.onMapTap = { }
        bottomControlsView.onPagerTap = { [weak self] in
            self?.showNextPage()
        }
        bottomControlsView.onListTap = { [weak self] in
            self?.showCitySearch()
        }
    }

    private func setupSavedCitiesObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSavedCitiesDidChange),
            name: .savedCitiesDidChange,
            object: nil
        )
    }

    @objc private func handleSavedCitiesDidChange() {
        reloadSources(selecting: activeSource, animated: false)
    }

    private func reloadSources(selecting preferredSource: WeatherLocationSource, animated: Bool) {
        let previousIndex = activePageIndex
        let previousSource = activeSource
        sources = makeSources()
        prunePageCache()

        activePageIndex = index(of: preferredSource)
            ?? index(of: previousSource)
            ?? nearestAvailableIndex(from: previousIndex)

        let targetSource = sources[activePageIndex]

        let targetViewController = page(for: targetSource)
        let currentViewController = currentMainViewController

        if currentViewController !== targetViewController {
            pageViewController.setViewControllers(
                [targetViewController],
                direction: pageDirection(from: previousIndex, to: activePageIndex),
                animated: animated
            )
        }

        updateBottomControls()
        setNeedsStatusBarAppearanceUpdate()
    }

    private func makeSources() -> [WeatherLocationSource] {
        [.currentLocation] + savedCitiesStore.loadCities().map(WeatherLocationSource.fixedCity)
    }

    private func prunePageCache() {
        let activePageIDs = Set(sources.map(\.pageID))
        pageCache = pageCache.filter { activePageIDs.contains($0.key) }
    }

    private func page(for source: WeatherLocationSource) -> MainViewController {
        let pageID = source.pageID
        if let cachedViewController = pageCache[pageID] {
            return cachedViewController
        }

        let viewController = makeMainViewController(source)
        pageCache[pageID] = viewController
        return viewController
    }

    private func index(of source: WeatherLocationSource) -> Int? {
        sources.firstIndex { $0.pageID == source.pageID }
    }

    private func nearestAvailableIndex(from previousIndex: Int) -> Int {
        guard let lastIndex = sources.indices.last else {
            return sources.startIndex
        }

        return min(max(previousIndex, sources.startIndex), lastIndex)
    }

    private func pageDirection(from currentIndex: Int, to targetIndex: Int) -> UIPageViewController.NavigationDirection {
        targetIndex >= currentIndex ? .forward : .reverse
    }

    private func updateBottomControls() {
        bottomControlsView.configurePager(
            currentPage: activePageIndex,
            totalPages: sources.count
        )
    }

    private func showNextPage() {
        let nextIndex = sources.index(after: activePageIndex)
        guard sources.indices.contains(nextIndex) else {
            return
        }

        setActivePage(index: nextIndex, animated: true, emitsFeedback: false)
    }

    private func setActivePage(index: Int, animated: Bool, emitsFeedback: Bool) {
        guard sources.indices.contains(index),
              index != activePageIndex else {
            return
        }

        let previousIndex = activePageIndex
        activePageIndex = index
        pageViewController.setViewControllers(
            [page(for: sources[index])],
            direction: pageDirection(from: previousIndex, to: index),
            animated: animated
        ) { [weak self] completed in
            guard completed else { return }
            self?.updateBottomControls()
            self?.setNeedsStatusBarAppearanceUpdate()
            if emitsFeedback {
                self?.emitPageFeedback()
            }
        }
        updateBottomControls()
    }

    private func showCitySearch() {
        guard presentedViewController == nil else { return }

        let backgroundTheme = currentMainViewController?.currentWeatherTheme() ?? .current
        let searchViewController = makeCitySearchViewController(backgroundTheme) { [weak self] selection in
            self?.handleCitySelection(selection)
        }
        searchViewController.onClose = { [weak self] in
            self?.dismiss(animated: true)
        }
        searchViewController.modalPresentationStyle = .custom
        searchViewController.transitioningDelegate = citySearchTransitioningDelegate
        searchViewController.modalPresentationCapturesStatusBarAppearance = true

        present(searchViewController, animated: true)
    }

    private func handleCitySelection(_ selection: CitySelection) {
        let targetSource: WeatherLocationSource
        switch selection {
        case .currentLocation:
            targetSource = .currentLocation
        case .savedCity(let city):
            targetSource = .fixedCity(city)
        }

        reloadSources(selecting: targetSource, animated: false)
        dismiss(animated: true)
    }

    private func emitPageFeedback() {
        AppHaptics.lightImpact()
    }
}

#if DEBUG
extension WeatherPagerViewController {

    func configureDebugScript(_ script: DebugPagerScript) {
        debugScript = script
    }

    private func runDebugScriptIfNeeded() {
        guard let delay = debugScript?.deleteActiveCityAfter,
              delay >= 0 else {
            return
        }

        debugScriptTask?.cancel()
        debugScriptTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                return
            }

            self?.deleteActiveCityForDebug()
        }
    }

    private func deleteActiveCityForDebug() {
        guard case .fixedCity(let city) = activeSource else { return }
        savedCitiesStore.removeCity(id: city.id)
    }
}
#endif

private final class WeatherCityListTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        WeatherCityListAnimator(isPresenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        WeatherCityListAnimator(isPresenting: false)
    }
}

private final class WeatherCityListAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private let isPresenting: Bool
    private let duration: TimeInterval = 0.42
    private let backgroundTransform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        .translatedBy(x: 0, y: -10)
    private let foregroundOffset = CGAffineTransform(translationX: 0, y: 32)

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        isPresenting
            ? animatePresentation(using: transitionContext)
            : animateDismissal(using: transitionContext)
    }

    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to),
              let toViewController = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let fromView = transitionContext.view(forKey: .from)

        toView.frame = transitionContext.finalFrame(for: toViewController)
        toView.alpha = 0
        toView.transform = foregroundOffset
        containerView.addSubview(toView)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.92,
            initialSpringVelocity: 0.3,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            fromView?.transform = self.backgroundTransform
            fromView?.alpha = 0.88
            toView.alpha = 1
            toView.transform = .identity
        } completion: { completed in
            if transitionContext.transitionWasCancelled {
                fromView?.transform = .identity
                fromView?.alpha = 1
                toView.removeFromSuperview()
            }
            transitionContext.completeTransition(completed && !transitionContext.transitionWasCancelled)
        }
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }

        let toView = transitionContext.view(forKey: .to)
        if let toView, toView.superview == nil {
            transitionContext.containerView.insertSubview(toView, belowSubview: fromView)
        }

        toView?.transform = backgroundTransform
        toView?.alpha = 0.88

        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.94,
            initialSpringVelocity: 0.2,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            fromView.alpha = 0
            fromView.transform = self.foregroundOffset
            toView?.transform = .identity
            toView?.alpha = 1
        } completion: { completed in
            if transitionContext.transitionWasCancelled {
                fromView.alpha = 1
                fromView.transform = .identity
                toView?.transform = self.backgroundTransform
                toView?.alpha = 0.88
            }
            transitionContext.completeTransition(completed && !transitionContext.transitionWasCancelled)
        }
    }
}

extension WeatherPagerViewController: UIPageViewControllerDataSource {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let mainViewController = viewController as? MainViewController,
              let index = index(of: mainViewController.locationSource),
              index > sources.startIndex else {
            return nil
        }

        return page(for: sources[sources.index(before: index)])
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let mainViewController = viewController as? MainViewController,
              let index = index(of: mainViewController.locationSource) else {
            return nil
        }

        let nextIndex = sources.index(after: index)
        guard sources.indices.contains(nextIndex) else { return nil }
        return page(for: sources[nextIndex])
    }
}

extension WeatherPagerViewController: UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let mainViewController = pageViewController.viewControllers?.first as? MainViewController else {
            return
        }

        guard let newIndex = index(of: mainViewController.locationSource),
              newIndex != activePageIndex else {
            return
        }

        activePageIndex = newIndex
        updateBottomControls()
        setNeedsStatusBarAppearanceUpdate()
        emitPageFeedback()
    }
}

private extension WeatherLocationSource {

    var pageID: String {
        switch self {
        case .currentLocation:
            return "currentLocation"
        case .fixedCity(let city):
            return "savedCity:\(city.id)"
        }
    }
}
