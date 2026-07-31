import Foundation

final class CitySearchViewModel {

    var onStateChanged: ((CitySearchState) -> Void)?
    var onSelectionRequested: ((CitySelection) -> Void)?

    private let savedCitiesStore: SavedCitiesStoreProtocol
    private let citySearchClient: CitySearchClientProtocol
    private let previewLoader: CityWeatherPreviewLoader

    private var savedCities: [SavedCity] = []
    private var cityPreviews: [CityWeatherPreviewUIModel] = []
    private var searchResultsState: CitySearchResultsState = .emptyQuery
    private var completions: [CitySearchCompletionModel] = []
    private var activeQuery = ""
    private var debounceTask: Task<Void, Never>?
    private var previewTasks: [Task<Void, Never>] = []
    private var selectionTask: Task<Void, Never>?

    init(
        savedCitiesStore: SavedCitiesStoreProtocol,
        citySearchClient: CitySearchClientProtocol,
        previewLoader: CityWeatherPreviewLoader
    ) {
        self.savedCitiesStore = savedCitiesStore
        self.citySearchClient = citySearchClient
        self.previewLoader = previewLoader
    }

    deinit {
        debounceTask?.cancel()
        previewTasks.forEach { $0.cancel() }
        selectionTask?.cancel()
    }

    func viewDidLoad() {
        reloadSavedCities()
        loadWeatherPreviews()
    }

    func updateQuery(_ query: String) {
        debounceTask?.cancel()
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        activeQuery = trimmedQuery

        guard !trimmedQuery.isEmpty else {
            completions = []
            searchResultsState = .emptyQuery
            citySearchClient.clear()
            emitState()
            return
        }

        searchResultsState = .searching
        emitState()

        debounceTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                guard let self, self.activeQuery == trimmedQuery else { return }

                let completions = try await self.citySearchClient.searchCompletions(for: trimmedQuery)
                guard !Task.isCancelled,
                      self.activeQuery == trimmedQuery else {
                    return
                }

                self.applySearchCompletions(completions)
            } catch is CancellationError {
                return
            } catch {
                guard let self, self.activeQuery == trimmedQuery else { return }
                self.completions = []
                self.searchResultsState = .error("Не удалось выполнить поиск")
                self.emitState()
                return
            }
        }
    }

    func clearSearch() {
        debounceTask?.cancel()
        activeQuery = ""
        completions = []
        citySearchClient.clear()
        searchResultsState = .emptyQuery
        emitState()
    }

    func selectSavedCity(at index: Int) {
        guard cityPreviews.indices.contains(index) else { return }
        let preview = cityPreviews[index]

        if preview.isCurrentLocation {
            onSelectionRequested?(.currentLocation)
            return
        }

        guard let city = preview.city else { return }
        onSelectionRequested?(.savedCity(city))
    }

    func canDeleteCity(at index: Int) -> Bool {
        guard cityPreviews.indices.contains(index) else { return false }
        return !cityPreviews[index].isCurrentLocation
    }

    func deleteCity(at index: Int) {
        guard canDeleteCity(at: index), let city = cityPreviews[index].city else { return }
        savedCitiesStore.removeCity(id: city.id)
        reloadSavedCities()
        loadWeatherPreviews()
    }

    func selectSearchResult(at index: Int) {
        guard completions.indices.contains(index) else { return }

        let selectedCompletion = completions[index]
        searchResultsState = .searching
        emitState()

        selectionTask?.cancel()
        selectionTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let city = try await self.citySearchClient.resolve(selectedCompletion)

                let selectedCity: SavedCity
                switch self.savedCitiesStore.saveCityIfNeeded(city) {
                case .added(let city), .existing(let city):
                    selectedCity = city
                case .failed:
                    self.searchResultsState = .error("Не удалось сохранить город")
                    self.emitState()
                    return
                }

                self.clearSearch()
                self.reloadSavedCities()
                self.loadWeatherPreviews()
                self.onSelectionRequested?(.savedCity(selectedCity))
            } catch {
                self.searchResultsState = .error("Не удалось получить координаты города")
                self.emitState()
            }
        }
    }

    private func applySearchCompletions(_ completions: [CitySearchCompletionModel]) {
        self.completions = completions
        let suggestions = completions.map {
            CitySearchSuggestionUIModel(title: $0.title, subtitle: $0.subtitle)
        }

        searchResultsState = suggestions.isEmpty ? .noResults : .results(suggestions)
        emitState()
    }

    private func reloadSavedCities() {
        savedCities = savedCitiesStore.loadCities()
        cityPreviews = previewLoader.makeInitialPreviews(savedCities: savedCities)
        emitState()
    }

    private func loadWeatherPreviews() {
        previewTasks.forEach { $0.cancel() }
        previewTasks.removeAll()

        loadCurrentLocationPreview()
        savedCities.forEach(loadSavedCityPreview)
    }

    private func loadCurrentLocationPreview() {
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            guard let update = await self.previewLoader.loadCurrentLocationPreview(),
                  !Task.isCancelled else { return }
            self.applyPreviewUpdate(update)
        }

        previewTasks.append(task)
    }

    private func loadSavedCityPreview(_ city: SavedCity) {
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            guard let update = await self.previewLoader.loadSavedCityPreview(city),
                  !Task.isCancelled else { return }
            self.applyPreviewUpdate(update)
        }

        previewTasks.append(task)
    }

    private func applyPreviewUpdate(_ update: CityWeatherPreviewUpdate) {
        guard let index = cityPreviews.firstIndex(where: { $0.id == update.id }) else { return }
        let currentPreview = cityPreviews[index]

        cityPreviews[index] = CityWeatherPreviewUIModel(
            id: currentPreview.id,
            title: update.title ?? currentPreview.title,
            subtitle: update.subtitle ?? currentPreview.subtitle,
            isCurrentLocation: currentPreview.isCurrentLocation,
            city: currentPreview.city,
            theme: update.theme ?? currentPreview.theme,
            state: update.state
        )
        emitState()
    }

    private func emitState() {
        onStateChanged?(CitySearchState(
            cityPreviews: cityPreviews,
            resultsState: searchResultsState
        ))
    }
}
