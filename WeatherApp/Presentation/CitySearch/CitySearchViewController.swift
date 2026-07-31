import UIKit
import SnapKit

final class CitySearchViewController: UIViewController {

    var onCitySelection: ((CitySelection) -> Void)?
    var onClose: (() -> Void)?

    private enum Section: Int, CaseIterable {
        case savedCities
        case searchResults
    }

    private enum SearchResultCellState {
        case searching
        case results([CitySearchSuggestionUIModel])
        case noResults
        case error(String)
    }

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let headerHeight: CGFloat = 68
        static let searchFieldHeight: CGFloat = 48
        static let restingSearchBottomInset: CGFloat = 8
        static let keyboardSearchGap: CGFloat = 10
        static let tableBottomPadding: CGFloat = 28

        static var restingTableBottomInset: CGFloat {
            searchFieldHeight + restingSearchBottomInset + tableBottomPadding
        }
    }

    private let headerContainer = UIView()
    private let searchTextField = SearchTextField()

    private let titleLabel = AppTextStyle.label(
        style: .systemFont(ofSize: 42, weight: .bold),
        color: AppColors.textPrimary
    )

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = AppColors.textPrimary
        button.backgroundColor = AppColors.citySearchMoreButtonBackground
        button.layer.cornerRadius = 24
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1.0
        button.layer.borderColor = AppColors.citySearchMoreButtonBorder.cgColor
        button.accessibilityLabel = "Закрыть"
        button.addTarget(self, action: #selector(handleCloseTap), for: .touchUpInside)
        return button
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .interactive
        let initialInsets = UIEdgeInsets(top: 10, left: 0, bottom: Layout.restingTableBottomInset, right: 0)
        tableView.contentInset = initialInsets
        tableView.verticalScrollIndicatorInsets = initialInsets
        return tableView
    }()

    private let viewModel: CitySearchViewModel
    private let backgroundTheme: WeatherTheme
    private var state = CitySearchState(cityPreviews: [], resultsState: .emptyQuery)
    private var searchBottomConstraint: Constraint?
    private var gradientApplied = false

    init(viewModel: CitySearchViewModel, backgroundTheme: WeatherTheme) {
        self.viewModel = viewModel
        self.backgroundTheme = backgroundTheme
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !gradientApplied {
            GradientManager.shared.applyGradient(
                to: view.layer,
                timeOfDay: backgroundTheme.timeOfDay,
                isRaining: backgroundTheme.isRaining
            )
            gradientApplied = true
        } else {
            view.layer.sublayers?
                .first(where: { $0.name == GradientManager.gradientLayerName })?
                .frame = view.bounds
        }
    }

    private func setupUI() {
        view.backgroundColor = .clear
        titleLabel.text = "Погода"
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.82

        view.addSubview(headerContainer)
        view.addSubview(tableView)
        view.addSubview(searchTextField)

        headerContainer.addSubview(titleLabel)
        headerContainer.addSubview(closeButton)

        headerContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.headerHeight)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(headerContainer).offset(Layout.horizontalInset + 4)
            make.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-16)
            make.centerY.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.trailing.equalTo(headerContainer).inset(Layout.horizontalInset + 4)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(48)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.bottom.equalToSuperview()
        }

        searchTextField.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.height.equalTo(Layout.searchFieldHeight)
            searchBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide)
                .inset(Layout.restingSearchBottomInset)
                .constraint
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            CityWeatherCardCell.self,
            forCellReuseIdentifier: CityWeatherCardCell.reuseIdentifier
        )
        tableView.register(
            CitySearchResultCell.self,
            forCellReuseIdentifier: CitySearchResultCell.reuseIdentifier
        )
        tableView.register(
            CitySearchMessageCell.self,
            forCellReuseIdentifier: CitySearchMessageCell.reuseIdentifier
        )
        tableView.tableFooterView = makeWeatherDataFooter()

        searchTextField.onTextChanged = { [weak self] text in
            self?.viewModel.updateQuery(text)
        }

        searchTextField.onClear = { [weak self] in
            self?.viewModel.clearSearch()
        }
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] state in
            self?.state = state
            self?.tableView.reloadData()
        }

        viewModel.onSelectionRequested = { [weak self] selection in
            self?.onCitySelection?(selection)
        }
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardChange),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardChange),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func handleKeyboardChange(_ notification: Notification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        let convertedKeyboardFrame = view.convert(keyboardFrame, from: nil)
        let overlap = view.bounds.intersection(convertedKeyboardFrame).height
        let hasVisibleKeyboard = overlap > 0
        let bottomInset = hasVisibleKeyboard
            ? max(Layout.restingSearchBottomInset, overlap - view.safeAreaInsets.bottom + Layout.keyboardSearchGap)
            : Layout.restingSearchBottomInset

        searchBottomConstraint?.update(inset: bottomInset)
        updateFloatingSearchInsets(searchBottomInset: bottomInset)

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    private func updateFloatingSearchInsets(searchBottomInset: CGFloat) {
        let tableBottomInset = Layout.searchFieldHeight + searchBottomInset + Layout.tableBottomPadding
        tableView.contentInset.bottom = tableBottomInset
        tableView.verticalScrollIndicatorInsets.bottom = tableBottomInset
    }

    private func makeSectionHeader(title: String) -> UIView {
        let containerView = UIView()
        let titleLabel = AppTextStyle.label(
            style: .systemFont(ofSize: 13, weight: .semibold),
            color: AppColors.textPrimary.withAlphaComponent(0.56)
        )
        titleLabel.text = title.uppercased()

        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().inset(6)
        }

        return containerView
    }

    private func makeWeatherDataFooter() -> UIView {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 78))
        let label = AppTextStyle.label(
            style: .systemFont(ofSize: 15, weight: .medium),
            color: AppColors.textPrimary.withAlphaComponent(0.48),
            alignment: .center
        )
        label.text = "Подробнее о данных погоды и карты"
        label.numberOfLines = 2

        containerView.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        return containerView
    }

    @objc private func handleCloseTap() {
        view.endEditing(true)
        onClose?()
    }
}

extension CitySearchViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }

        switch section {
        case .savedCities:
            guard case .emptyQuery = state.resultsState else {
                return 0
            }
            return state.cityPreviews.count

        case .searchResults:
            switch state.resultsState {
            case .results(let suggestions):
                return suggestions.count
            case .emptyQuery:
                return 0
            case .searching, .noResults, .error:
                return 1
            }
        }
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        switch section {
        case .savedCities:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: CityWeatherCardCell.reuseIdentifier,
                for: indexPath
            ) as? CityWeatherCardCell
            guard let cell, state.cityPreviews.indices.contains(indexPath.row) else {
                return UITableViewCell()
            }
            cell.configure(with: state.cityPreviews[indexPath.row])
            return cell

        case .searchResults:
            guard let cellState = makeSearchResultCellState() else {
                return UITableViewCell()
            }
            return makeSearchResultCell(tableView, indexPath: indexPath, state: cellState)
        }
    }

    private func makeSearchResultCellState() -> SearchResultCellState? {
        switch state.resultsState {
        case .emptyQuery:
            return nil
        case .searching:
            return .searching
        case .results(let suggestions):
            return .results(suggestions)
        case .noResults:
            return .noResults
        case .error(let message):
            return .error(message)
        }
    }

    private func makeSearchResultCell(
        _ tableView: UITableView,
        indexPath: IndexPath,
        state: SearchResultCellState
    ) -> UITableViewCell {
        switch state {
        case .results(let suggestions):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: CitySearchResultCell.reuseIdentifier,
                for: indexPath
            ) as? CitySearchResultCell
            guard let cell, suggestions.indices.contains(indexPath.row) else {
                return UITableViewCell()
            }
            cell.configure(with: suggestions[indexPath.row])
            return cell

        case .searching:
            return makeMessageCell(message: "Идёт поиск", showsLoading: true)

        case .noResults:
            return makeMessageCell(message: "Ничего не найдено", showsLoading: false)

        case .error(let message):
            return makeMessageCell(message: message, showsLoading: false)
        }
    }

    private func makeMessageCell(message: String, showsLoading: Bool) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CitySearchMessageCell.reuseIdentifier
        ) as? CitySearchMessageCell
        guard let cell else { return UITableViewCell() }
        cell.configure(message: message, showsLoading: showsLoading)
        return cell
    }
}

extension CitySearchViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableView.automaticDimension
        }

        switch section {
        case .savedCities:
            return 148
        case .searchResults:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = Section(rawValue: section) else { return nil }

        switch section {
        case .savedCities:
            return nil
        case .searchResults:
            guard case .emptyQuery = state.resultsState else {
                return makeSectionHeader(title: "Результаты поиска")
            }
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let section = Section(rawValue: section) else { return 0 }

        switch section {
        case .savedCities:
            return 0.01
        case .searchResults:
            guard case .emptyQuery = state.resultsState else {
                return 34
            }
            return 0.01
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .savedCities:
            viewModel.selectSavedCity(at: indexPath.row)

        case .searchResults:
            guard case .results = state.resultsState else { return }
            viewModel.selectSearchResult(at: indexPath.row)
        }
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard Section(rawValue: indexPath.section) == .savedCities,
              viewModel.canDeleteCity(at: indexPath.row) else {
            return nil
        }

        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, completion in
            self?.viewModel.deleteCity(at: indexPath.row)
            AppHaptics.deleteImpact()
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
